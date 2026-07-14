import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_expense_tracker/state/app_model.dart';
import 'package:family_expense_tracker/utils/format.dart';

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('spending by a member not in the list is still shown (not hidden)',
      () async {
    final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'g@e.com', displayName: 'G'));
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({'familyId': 'f1'});
    await db.collection('families').doc('f1').set({
      'name': 'Fam', 'ownerUid': 'u1', 'inviteCode': 'AAA111',
      'memberNames': ['Sujatha D', 'Gokul B'],
      'members': {'u1': {'name': 'G', 'email': 'g@e.com'}},
    });
    await db.collection('families').doc('f1').collection('settings').doc('config').set({
      'incomeByMonth': {}, 'budgetsByMonth': {}, 'totalOverrideByMonth': {},
    });
    final month = ym(DateTime.now());
    final ex = db.collection('families').doc('f1').collection('expenses');
    // Stored under a mismatched name "Sujatha" (with a stray space) + a matching one.
    await ex.add({'date': '$month-05', 'desc': 'watch', 'cat': 'Shopping', 'mem': 'Sujatha ', 'amt': 2000, 'pay': 'UPI'});
    await ex.add({'date': '$month-06', 'desc': 'veg', 'cat': 'Groceries', 'mem': 'Gokul B', 'amt': 500, 'pay': 'Cash'});

    final m = AppModel(auth: auth, db: db);
    await _settle();

    // Total is correct.
    expect(m.summary.totalSpent, 2500);
    // The "Sujatha" spend is trimmed and surfaced in the breakdown, not hidden.
    expect(m.breakdownMembers.contains('Sujatha'), true);
    expect(m.summary.spentByMem['Sujatha'], 2000);
    expect(m.summary.spentByMem['Gokul B'], 500);
    // Sum of the breakdown equals the total (nothing missing).
    final sum = m.breakdownMembers
        .fold<double>(0, (s, mb) => s + (m.summary.spentByMem[mb] ?? 0));
    expect(sum, m.summary.totalSpent);

    m.dispose();
  });
}
