import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_expense_tracker/state/app_model.dart';

Future<void> _settle() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('signed-in user with no family lands on needFamily (never loadError)',
      () async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'a@b.com', displayName: 'A'),
    );
    final model = AppModel(auth: auth, db: db);
    await _settle();
    // A successful read that shows no family => create/join screen, not error.
    expect(model.stage, AppStage.needFamily);
  });

  test('createFamily never creates a second family when one already exists',
      () async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'a@b.com', displayName: 'A'),
    );
    await db.collection('users').doc('u1').set({'familyId': 'famX'});
    await db.collection('families').doc('famX').set({
      'name': 'Fam',
      'ownerUid': 'u1',
      'inviteCode': 'CODEXX',
      'memberNames': ['A'],
      'members': {
        'u1': {'name': 'A', 'email': 'a@b.com'}
      },
    });
    await db
        .collection('families')
        .doc('famX')
        .collection('settings')
        .doc('config')
        .set({'incomeByMonth': {}, 'budgetsByMonth': {}, 'totalOverrideByMonth': {}});

    final model = AppModel(auth: auth, db: db);
    await _settle();
    expect(model.stage, AppStage.ready);

    // Even if the create flow is somehow reached, it must not duplicate.
    await model.createFamily('Another Family', ['A']);
    final fams = await db.collection('families').get();
    expect(fams.docs.length, 1);
    expect(model.family?.id, 'famX');
  });
}
