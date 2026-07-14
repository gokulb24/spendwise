import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/constants.dart';
import '../models/debt.dart';
import '../models/expense.dart';
import '../models/family.dart';
import '../models/goal.dart';
import '../models/investment.dart';
import '../models/recurring.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../utils/format.dart';
import '../utils/summary.dart';

enum AppStage { loading, signedOut, needFamily, ready, loadError }

/// Single source of truth: Firebase auth + live Firestore family data + UI state.
/// The data model is identical to the web app, so both share one Firestore.
class AppModel extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AppStage stage = AppStage.loading;
  User? user;
  Family? family;
  String currentMonth = ym(DateTime.now());

  // Live family data.
  List<Expense> expenses = [];
  Map<String, Map<String, double>> incomeByMonth = {};
  Map<String, Map<String, double>> budgetsByMonth = {};
  Map<String, double> totalOverrideByMonth = {};
  List<Goal> goals = [];
  List<Recurring> recurring = [];
  List<Debt> debts = [];
  List<Investment> investments = [];
  List<Reminder> reminders = [];
  bool fromCache = false; // true when showing offline-cached data
  bool _recurringRan = false; // generate due recurring entries once per session

  final List<StreamSubscription> _subs = [];
  StreamSubscription<User?>? _authSub;

  AppModel({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance {
    _authSub = _auth.authStateChanges().listen(_onAuth);
  }

  List<String> get members =>
      (family?.memberNames.isNotEmpty ?? false) ? family!.memberNames : const [];

  /// The family's category list, falling back to the built-in defaults.
  List<String> get categories =>
      (family?.categories.isNotEmpty ?? false) ? family!.categories : kCategories;

  Future<void> setCategories(List<String> cats) =>
      _familyDoc.update({'categories': cats});

  Future<void> addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || categories.contains(trimmed)) return Future.value();
    return setCategories([...categories, trimmed]);
  }

  Future<void> removeCategory(String name) =>
      setCategories(categories.where((c) => c != name).toList());

  // ---- auth ---------------------------------------------------------------
  Future<void> _onAuth(User? u) async {
    user = u;
    _cancelDataSubs();
    if (u == null) {
      family = null;
      _clearData();
      stage = AppStage.signedOut;
      notifyListeners();
      return;
    }
    // Find which family this user belongs to. Try the server; on a network
    // hiccup fall back to whatever is cached on-device. We only ever send an
    // existing member to the "create/join family" screen when we have DEFINITELY
    // read their profile and it has no family — otherwise a transient offline
    // read could make them create a duplicate family.
    DocumentSnapshot<Map<String, dynamic>>? udoc;
    try {
      udoc = await _db.collection('users').doc(u.uid).get();
    } catch (_) {
      try {
        udoc = await _db
            .collection('users')
            .doc(u.uid)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        udoc = null;
      }
    }
    final fid = udoc?.data()?['familyId'] as String?;
    if (fid != null && fid.isNotEmpty) {
      _enterFamily(fid);
    } else if (udoc != null) {
      // Read SUCCEEDED (profile may be brand-new/absent) but there's no family
      // yet → genuinely needs to create or join one.
      stage = AppStage.needFamily;
      notifyListeners();
    } else {
      // Read genuinely FAILED (offline with no cache, or an error). Don't risk
      // a duplicate family — show a retryable error instead of "create family".
      stage = AppStage.loadError;
      notifyListeners();
    }
  }

  /// Re-attempt loading the signed-in user's family (used by the error screen).
  Future<void> retry() async {
    stage = AppStage.loading;
    notifyListeners();
    await _onAuth(_auth.currentUser);
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUp(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(name);
    await _db.collection('users').doc(cred.user!.uid).set(
        {'name': name, 'email': email}, SetOptions(merge: true));
    // authStateChanges already fired; refresh so displayName is present.
    user = _auth.currentUser;
  }

  Future<void> sendReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Sign in (or sign up, on first use) with a Google account.
  Future<void> signInWithGoogle() async {
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
          code: 'no-google-id-token',
          message: 'Could not get Google credentials. '
              'Check that the SHA-1 fingerprint and Google sign-in are set up.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _auth.signInWithCredential(credential);
    final u = cred.user!;
    await _db.collection('users').doc(u.uid).set(
        {'name': u.displayName ?? '', 'email': u.email ?? ''},
        SetOptions(merge: true));
    user = _auth.currentUser;
  }

  Future<void> signOut() async {
    _cancelDataSubs();
    _clearData();
    family = null;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // not signed in with Google — fine to ignore
    }
    await _auth.signOut();
  }

  // ---- family create / join ----------------------------------------------
  Future<void> createFamily(String name, List<String> memberNames) async {
    final uid = user!.uid;
    // Guard: if this user already belongs to a family, enter it instead of
    // creating a duplicate (belt-and-braces against the old offline bug).
    try {
      final existing = await _db.collection('users').doc(uid).get();
      final existingFid = existing.data()?['familyId'] as String?;
      if (existingFid != null && existingFid.isNotEmpty) {
        _enterFamily(existingFid);
        return;
      }
    } catch (_) {
      // Couldn't verify — proceed to create (rare now that _onAuth guards this).
    }
    final code = generateInviteCode(uid.hashCode);
    final ref = _db.collection('families').doc();
    await ref.set({
      'name': name,
      'ownerUid': uid,
      'inviteCode': code,
      'memberNames': memberNames,
      'members': {
        uid: {'name': user!.displayName ?? '', 'email': user!.email ?? ''}
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Public lookup so others can join by code without being able to read/list
    // every family. Holds only the family id — no names or emails.
    await _db.collection('invites').doc(code).set({'familyId': ref.id});
    await ref.collection('settings').doc('config').set({
      'incomeByMonth': {},
      'budgetsByMonth': {},
      'totalOverrideByMonth': {},
    });
    await _db.collection('users').doc(uid).set(
        {'familyId': ref.id, 'name': user!.displayName ?? '', 'email': user!.email ?? ''},
        SetOptions(merge: true));
    _enterFamily(ref.id);
  }

  /// Returns null on success, or a human-readable error.
  Future<String?> joinFamily(String code) async {
    final uid = user!.uid;
    final invite =
        await _db.collection('invites').doc(code.trim().toUpperCase()).get();
    final fid = invite.data()?['familyId'] as String?;
    if (!invite.exists || fid == null || fid.isEmpty) {
      return 'No family found with that code.';
    }
    try {
      // Merge ourselves into the members map. Using set(merge:true) with a
      // nested map (rather than a 'members.$uid' field path) is robust for any
      // Firebase UID, including ones that start with a digit.
      await _db.collection('families').doc(fid).set({
        'members': {
          uid: {
            'name': user!.displayName ?? '',
            'email': user!.email ?? '',
          }
        }
      }, SetOptions(merge: true));
    } catch (_) {
      return 'Could not join that family — please check the code and try again.';
    }
    await _db.collection('users').doc(uid).set(
        {'familyId': fid, 'name': user!.displayName ?? '', 'email': user!.email ?? ''},
        SetOptions(merge: true));
    _enterFamily(fid);
    return null;
  }

  Future<void> updateFamily(String name, List<String> memberNames) =>
      _familyDoc.update({'name': name, 'memberNames': memberNames});

  DocumentReference<Map<String, dynamic>> get _familyDoc =>
      _db.collection('families').doc(family!.id);

  // ---- live listeners -----------------------------------------------------
  void _enterFamily(String fid) {
    _cancelDataSubs();
    _clearData();
    stage = AppStage.ready;
    final fref = _db.collection('families').doc(fid);

    _subs.add(fref.snapshots().listen((doc) {
      final d = doc.data();
      if (d == null) return;
      family = Family.fromMap(fid, d);
      notifyListeners();
    }));

    _subs.add(
        fref.collection('settings').doc('config').snapshots().listen((doc) {
      final d = doc.data() ?? {};
      incomeByMonth = _numMapMap(d['incomeByMonth']);
      budgetsByMonth = _numMapMap(d['budgetsByMonth']);
      totalOverrideByMonth = _numMap(d['totalOverrideByMonth']);
      notifyListeners();
    }));

    _subs.add(fref.collection('expenses').snapshots().listen((snap) {
      expenses = snap.docs
          .map((d) => Expense.fromMap(d.id, d.data()))
          .toList();
      fromCache = snap.metadata.isFromCache;
      notifyListeners();
    }));

    _subs.add(fref.collection('goals').snapshots().listen((snap) {
      goals = snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      notifyListeners();
    }));

    _subs.add(fref.collection('recurring').snapshots().listen((snap) {
      recurring =
          snap.docs.map((d) => Recurring.fromMap(d.id, d.data())).toList();
      notifyListeners();
      _generateDueRecurring(); // create any expenses that are now due
    }));

    _subs.add(fref.collection('debts').snapshots().listen((snap) {
      debts = snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.outstanding.compareTo(a.outstanding));
      notifyListeners();
    }));

    _subs.add(fref.collection('investments').snapshots().listen((snap) {
      investments =
          snap.docs.map((d) => Investment.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
      notifyListeners();
    }));

    _subs.add(fref.collection('reminders').snapshots().listen((snap) {
      reminders = snap.docs.map((d) => Reminder.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();
      // Keep on-device notifications in sync with the shared reminder list.
      NotificationService.rescheduleAll(reminders.where((r) => !r.done).toList());
    }));

    notifyListeners();
  }

  // ---- expense CRUD -------------------------------------------------------
  Future<void> addExpense(Expense e) {
    if (ymStr(e.date) != currentMonth) currentMonth = ymStr(e.date);
    return _familyDoc.collection('expenses').add({
      ...e.toMap(),
      'by': user?.uid,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateExpense(String id, Expense e) =>
      _familyDoc.collection('expenses').doc(id).update(e.toMap());

  Future<void> deleteExpense(String id) =>
      _familyDoc.collection('expenses').doc(id).delete();

  /// Possible duplicate: same amount, category and date already exists.
  Expense? findPossibleDuplicate(Expense e) {
    for (final x in expenses) {
      if (x.id != e.id &&
          x.amt == e.amt &&
          x.cat == e.cat &&
          x.date == e.date) {
        return x;
      }
    }
    return null;
  }

  // ---- goals --------------------------------------------------------------
  Future<void> saveGoal(Goal g) {
    final col = _familyDoc.collection('goals');
    return g.id.isEmpty ? col.add(g.toMap()) : col.doc(g.id).set(g.toMap());
  }

  Future<void> contributeToGoal(String id, double amount) =>
      _familyDoc.collection('goals').doc(id).update(
          {'saved': FieldValue.increment(amount)});

  Future<void> deleteGoal(String id) =>
      _familyDoc.collection('goals').doc(id).delete();

  // ---- recurring ----------------------------------------------------------
  Future<void> saveRecurring(Recurring r) {
    final col = _familyDoc.collection('recurring');
    return r.id.isEmpty ? col.add(r.toMap()) : col.doc(r.id).set(r.toMap());
  }

  Future<void> setRecurringActive(String id, bool active) =>
      _familyDoc.collection('recurring').doc(id).update({'active': active});

  Future<void> deleteRecurring(String id) =>
      _familyDoc.collection('recurring').doc(id).delete();

  // ---- debts --------------------------------------------------------------
  double get totalOutstanding =>
      debts.fold(0.0, (s, d) => s + (d.closed ? 0 : d.outstanding));

  Future<void> saveDebt(Debt d) {
    final col = _familyDoc.collection('debts');
    return d.id.isEmpty ? col.add(d.toMap()) : col.doc(d.id).set(d.toMap());
  }

  Future<void> deleteDebt(String id) =>
      _familyDoc.collection('debts').doc(id).delete();

  Future<void> setDebtClosed(String id, bool closed) =>
      _familyDoc.collection('debts').doc(id).update({'closed': closed});

  Future<void> addDebtPayment(String id, DebtPayment p) {
    final debt = debts.firstWhere((d) => d.id == id);
    final list = [...debt.payments, p]
      ..sort((a, b) => b.date.compareTo(a.date));
    return _familyDoc
        .collection('debts')
        .doc(id)
        .update({'payments': list.map((e) => e.toMap()).toList()});
  }

  Future<void> removeDebtPayment(String id, int index) {
    final debt = debts.firstWhere((d) => d.id == id);
    final list = [...debt.payments]..removeAt(index);
    return _familyDoc
        .collection('debts')
        .doc(id)
        .update({'payments': list.map((e) => e.toMap()).toList()});
  }

  // ---- investments --------------------------------------------------------
  double get totalInvested => investments.fold(0.0, (s, i) => s + i.invested);
  double get totalPortfolioValue =>
      investments.fold(0.0, (s, i) => s + i.currentValue);
  double get totalReturns => totalPortfolioValue - totalInvested;

  Future<void> saveInvestment(Investment inv) {
    final col = _familyDoc.collection('investments');
    return inv.id.isEmpty ? col.add(inv.toMap()) : col.doc(inv.id).set(inv.toMap());
  }

  Future<void> deleteInvestment(String id) =>
      _familyDoc.collection('investments').doc(id).delete();

  // ---- reminders ----------------------------------------------------------
  List<Reminder> get pendingReminders =>
      reminders.where((r) => !r.done).toList();
  List<Reminder> get overdueReminders =>
      reminders.where((r) => r.isOverdue).toList();
  Reminder? get nextReminder {
    final upcoming = reminders.where((r) => r.isPending).toList();
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> saveReminder(Reminder r) {
    final col = _familyDoc.collection('reminders');
    return r.id.isEmpty ? col.add(r.toMap()) : col.doc(r.id).set(r.toMap());
  }

  Future<void> setReminderDone(String id, bool done) =>
      _familyDoc.collection('reminders').doc(id).update({'done': done});

  Future<void> deleteReminder(String id) =>
      _familyDoc.collection('reminders').doc(id).delete();

  /// Materialise any recurring occurrences whose date has arrived, up to today.
  /// Generated expenses use a deterministic id (`rec_{recurringId}_{date}`) so
  /// two devices generating the same occurrence can't create duplicates.
  Future<void> _generateDueRecurring() async {
    if (_recurringRan || family == null) return;
    _recurringRan = true;
    final today = todayIso();
    final expCol = _familyDoc.collection('expenses');
    for (final r in recurring) {
      if (!r.active) continue;
      var next = r.nextDate;
      var guard = 0;
      while (next.compareTo(today) <= 0 && guard++ < 200) {
        final compact = next.replaceAll('-', '');
        await expCol.doc('rec_${r.id}_$compact').set({
          'date': next,
          'desc': r.desc,
          'cat': r.cat,
          'mem': r.mem,
          'amt': r.amt,
          'pay': r.pay,
          'tags': const ['recurring'],
          'note': '',
          'by': user?.uid,
          'at': DateTime.now().millisecondsSinceEpoch,
        });
        next = Recurring.advance(next, r.frequency);
      }
      if (next != r.nextDate) {
        await _familyDoc
            .collection('recurring')
            .doc(r.id)
            .update({'nextDate': next});
      }
    }
  }

  @visibleForTesting
  Future<void> reRunRecurringForTest() async {
    _recurringRan = false;
    await _generateDueRecurring();
  }

  // ---- budgets / income / override ---------------------------------------
  void _ensureMonth(String m) {
    budgetsByMonth[m] ??= Map<String, double>.from(kDefaultBudgets);
    final inc = incomeByMonth[m] ?? {};
    for (final mb in members) {
      inc[mb] ??= 0;
    }
    incomeByMonth[m] = inc;
  }

  Future<void> _saveSettings() => _familyDoc.collection('settings').doc('config').set({
        'incomeByMonth': incomeByMonth,
        'budgetsByMonth': budgetsByMonth,
        'totalOverrideByMonth': totalOverrideByMonth,
      }, SetOptions(merge: true));

  Future<void> setBudget(String cat, double value) {
    _ensureMonth(currentMonth);
    budgetsByMonth[currentMonth]![cat] = value;
    notifyListeners();
    return _saveSettings();
  }

  Future<void> setIncome(String member, double value) {
    _ensureMonth(currentMonth);
    incomeByMonth[currentMonth]![member] = value;
    notifyListeners();
    return _saveSettings();
  }

  Future<void> setTotalOverride(double? value) {
    if (value == null) {
      totalOverrideByMonth.remove(currentMonth);
    } else {
      totalOverrideByMonth[currentMonth] = value;
    }
    notifyListeners();
    return _saveSettings();
  }

  // ---- derived / helpers --------------------------------------------------
  void setMonth(String m) {
    currentMonth = m;
    notifyListeners();
  }

  Map<String, double> get currentBudgets {
    _ensureMonth(currentMonth);
    return budgetsByMonth[currentMonth]!;
  }

  Map<String, double> get currentIncome {
    _ensureMonth(currentMonth);
    return incomeByMonth[currentMonth]!;
  }

  double? get currentOverride => totalOverrideByMonth[currentMonth];

  List<Expense> get monthExpenses =>
      expenses.where((e) => ymStr(e.date) == currentMonth).toList();

  /// Members to show in spending breakdowns: the configured members PLUS anyone
  /// who has spending this month but isn't (or no longer is) in the list — so a
  /// name mismatch can never hide someone's spending.
  List<String> get breakdownMembers {
    final list = <String>[...members];
    for (final e in monthExpenses) {
      final mm = e.mem.trim();
      if (mm.isNotEmpty && !list.contains(mm)) list.add(mm);
    }
    return list;
  }

  List<String> get monthOptions =>
      buildMonths(currentMonth, expenses.map((e) => ymStr(e.date)));

  MonthSummary get summary => MonthSummary.compute(
        monthExpenses: monthExpenses,
        members: members,
        budgets: currentBudgets,
        incomeByMember: currentIncome,
        categories: categories,
        totalOverride: currentOverride,
      );

  // ---- internal -----------------------------------------------------------
  Map<String, Map<String, double>> _numMapMap(dynamic v) {
    final out = <String, Map<String, double>>{};
    if (v is Map) {
      v.forEach((k, inner) {
        out[k.toString()] = _numMap(inner);
      });
    }
    return out;
  }

  Map<String, double> _numMap(dynamic v) {
    final out = <String, double>{};
    if (v is Map) {
      v.forEach((k, val) {
        if (val is num) out[k.toString()] = val.toDouble();
      });
    }
    return out;
  }

  void _clearData() {
    expenses = [];
    incomeByMonth = {};
    budgetsByMonth = {};
    totalOverrideByMonth = {};
    goals = [];
    recurring = [];
    debts = [];
    investments = [];
    reminders = [];
    _recurringRan = false;
    currentMonth = ym(DateTime.now());
  }

  void _cancelDataSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  @override
  void dispose() {
    _cancelDataSubs();
    _authSub?.cancel();
    super.dispose();
  }
}
