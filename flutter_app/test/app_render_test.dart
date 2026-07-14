import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:family_expense_tracker/state/app_model.dart';
import 'package:family_expense_tracker/theme/app_theme.dart';
import 'package:family_expense_tracker/theme/theme_controller.dart';
import 'package:family_expense_tracker/services/app_lock.dart';
import 'package:family_expense_tracker/screens/home_shell.dart';

void main() {
  testWidgets('dashboard renders live family data end-to-end', (tester) async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'gokul@example.com', displayName: 'Gokul'),
    );
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({'familyId': 'fam1'});
    await db.collection('families').doc('fam1').set({
      'name': 'The Sharmas',
      'ownerUid': 'u1',
      'inviteCode': 'ABC123',
      'memberNames': ['Gokul', 'Brother', 'Mother'],
      'members': {'u1': {'name': 'Gokul', 'email': 'gokul@example.com'}},
    });
    await db.collection('families').doc('fam1').collection('settings').doc('config').set({
      'incomeByMonth': {}, 'budgetsByMonth': {}, 'totalOverrideByMonth': {},
    });
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await db.collection('families').doc('fam1').collection('expenses').add({
      'date': '$month-05', 'desc': 'Supermarket run', 'cat': 'Groceries',
      'mem': 'Gokul', 'amt': 1250, 'pay': 'UPI', 'by': 'u1',
    });

    final model = AppModel(auth: auth, db: db);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(ColorScheme.fromSeed(seedColor: kBrandSeed)),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppModel>.value(value: model),
          ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
          ChangeNotifierProvider<AppLock>(create: (_) => AppLock()),
        ],
        child: const HomeShell(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // data wired correctly
    expect(model.stage, AppStage.ready);
    expect(model.members, ['Gokul', 'Brother', 'Mother']);
    expect(model.monthExpenses.length, 1);
    expect(model.summary.totalSpent, 1250);

    // Dashboard tab shows the welcome header + the financial-health card
    // (both near the top of the scroll view).
    expect(find.textContaining('The Sharmas'), findsWidgets);
    expect(find.text('Financial Health'), findsOneWidget);

    // Navigate to the Expenses tab and confirm the live expense is listed.
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Supermarket run'), findsOneWidget);

    model.dispose();
  });
}
