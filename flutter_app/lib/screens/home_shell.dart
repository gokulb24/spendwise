import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_tile.dart';
import 'dashboard_tab.dart';
import 'expenses_tab.dart';
import 'goals_tab.dart';
import 'money_hub_tab.dart';
import 'profile_tab.dart';
import 'reports_tab.dart';

/// Root of the signed-in experience: a top bar (SpendWise + profile avatar),
/// Material 3 NavigationBar tabs and the Add-expense FAB.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Ask for notification permission early so reminders can fire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission();
    });
  }

  void _goToTab(int i) => setState(() => _index = i);

  void _openProfile(AppModel m) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
            value: m, child: const ProfileScreen())));
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final showFab = _index == 0 || _index == 1; // Dashboard & Expenses
    final initial = (m.user?.displayName?.trim().isNotEmpty ?? false)
        ? m.user!.displayName!.trim()[0].toUpperCase()
        : '?';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('SpendWise',
            style: context.texts.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Profile',
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openProfile(m),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(initial,
                      style: context.texts.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardTab(onSeeAllExpenses: () => _goToTab(1)),
          const ExpensesTab(),
          const GoalsTab(),
          const ReportsTab(),
          const MoneyHubTab(),
        ],
      ),
      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: showFab ? 1 : 0,
        child: FloatingActionButton.extended(
          heroTag: 'addExpenseFab',
          onPressed: () =>
              showEditExpense(context, context.read<AppModel>(), null),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Expenses'),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Goals'),
          NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'MoneyHub'),
        ],
      ),
    );
  }
}
