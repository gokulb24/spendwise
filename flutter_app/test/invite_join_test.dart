import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_expense_tracker/state/app_model.dart';

/// Let the async authStateChanges listener deliver the signed-in user.
Future<void> _settleAuth() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Verifies the hardened join flow: creating a family publishes an
/// `invites/{code}` lookup doc, and a second user can join purely from that
/// code (without ever reading/listing the families collection).
void main() {
  test('create publishes invite lookup; second user joins by code', () async {
    final db = FakeFirebaseFirestore();

    // ---- Owner creates a family --------------------------------------------
    final ownerAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'owner', email: 'owner@x.com', displayName: 'Owner'),
    );
    final owner = AppModel(auth: ownerAuth, db: db);
    await _settleAuth();
    await owner.createFamily('The Sharmas', ['Owner', 'Sibling']);

    // The family now exists and carries an invite code.
    final fams = await db.collection('families').get();
    expect(fams.docs.length, 1);
    final fid = fams.docs.first.id;
    final code = fams.docs.first.data()['inviteCode'] as String;
    expect(code, isNotEmpty);

    // A public invite lookup doc maps that code -> family id (and nothing more).
    final invite = await db.collection('invites').doc(code).get();
    expect(invite.exists, true);
    expect(invite.data(), {'familyId': fid});

    // ---- A second user joins with the code ---------------------------------
    final joinerAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'joiner', email: 'joiner@x.com', displayName: 'Joiner'),
    );
    final joiner = AppModel(auth: joinerAuth, db: db);
    await _settleAuth();

    // lower-case + whitespace should still resolve.
    final err = await joiner.joinFamily('  ${code.toLowerCase()}  ');
    expect(err, isNull);

    // The joiner is now a member of the same family.
    final famDoc = await db.collection('families').doc(fid).get();
    final members = (famDoc.data()!['members'] as Map).keys.toSet();
    expect(members, {'owner', 'joiner'});

    // And their profile points at the family.
    final joinerProfile = await db.collection('users').doc('joiner').get();
    expect(joinerProfile.data()!['familyId'], fid);
  });

  test('joining with an unknown code returns a friendly error', () async {
    final db = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u', email: 'u@x.com', displayName: 'U'),
    );
    final model = AppModel(auth: auth, db: db);
    await _settleAuth();
    final err = await model.joinFamily('NOPE99');
    expect(err, 'No family found with that code.');
  });
}
