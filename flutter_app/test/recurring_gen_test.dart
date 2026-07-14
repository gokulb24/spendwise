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
  test('recurring generator materialises due expenses idempotently', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'g@e.com', displayName: 'Gokul'),
    );
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({'familyId': 'fam1'});
    await db.collection('families').doc('fam1').set({
      'name': 'Fam',
      'ownerUid': 'u1',
      'inviteCode': 'AAA111',
      'memberNames': ['Gokul'],
      'members': {'u1': {'name': 'Gokul', 'email': 'g@e.com'}},
    });
    await db.collection('families').doc('fam1').collection('settings').doc('config').set({
      'incomeByMonth': {}, 'budgetsByMonth': {}, 'totalOverrideByMonth': {},
    });
    // A monthly rent that started 2 months ago and hasn't been generated.
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 2, 5);
    await db.collection('families').doc('fam1').collection('recurring').add({
      'desc': 'House rent', 'cat': 'Housing / Rent', 'mem': 'Gokul',
      'amt': 25000, 'pay': 'Bank Transfer', 'frequency': 'monthly',
      'nextDate': ymd(start), 'active': true,
    });

    final model = AppModel(auth: auth, db: db);
    await _settle();

    final gen = await db
        .collection('families').doc('fam1').collection('expenses').get();
    // Should have generated at least the two past-due occurrences.
    expect(gen.docs.length, greaterThanOrEqualTo(2));
    expect(gen.docs.every((d) => d.id.startsWith('rec_')), isTrue);
    expect(gen.docs.every((d) => d.data()['desc'] == 'House rent'), isTrue);

    // nextDate should now be in the future.
    final rec = await db
        .collection('families').doc('fam1').collection('recurring').get();
    final next = rec.docs.first.data()['nextDate'] as String;
    expect(next.compareTo(todayIso()) > 0, isTrue);

    // Running the generator again must NOT duplicate (deterministic ids).
    final before = gen.docs.length;
    await model.reRunRecurringForTest();
    await _settle();
    final gen2 = await db
        .collection('families').doc('fam1').collection('expenses').get();
    expect(gen2.docs.length, before);

    model.dispose();
  });
}
