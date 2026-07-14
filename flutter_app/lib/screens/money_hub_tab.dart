import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'debts_screen.dart';
import 'investments_screen.dart';
import 'recurring_screen.dart';

/// MoneyHub tab: groups the money-management tools (recurring, debts and
/// investments) so they have a clear home in the bottom navigation.
class MoneyHubTab extends StatelessWidget {
  const MoneyHubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;

    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      required Widget screen,
    }) {
      return Card(
        color: scheme.surfaceContainerLow,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: Icon(icon, color: scheme.onSecondaryContainer),
          ),
          title: Text(title),
          subtitle: Text(subtitle,
              style: context.texts.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChangeNotifierProvider.value(value: m, child: screen))),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text('MoneyHub',
            style: context.texts.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Your loans, recurring bills and investments in one place',
            style: context.texts.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        tile(
          icon: Icons.repeat,
          title: 'Recurring transactions',
          subtitle: '${m.recurring.length} set up · auto-added each cycle',
          screen: const RecurringScreen(),
        ),
        const SizedBox(height: 10),
        tile(
          icon: Icons.account_balance_outlined,
          title: 'Debt tracker',
          subtitle: m.debts.isEmpty
              ? 'Track loans, EMIs and repayments'
              : '${m.debts.where((d) => !d.isFullyPaid).length} active · ${inr(m.totalOutstanding)} outstanding',
          screen: const DebtsScreen(),
        ),
        const SizedBox(height: 10),
        tile(
          icon: Icons.trending_up,
          title: 'Investments',
          subtitle: m.investments.isEmpty
              ? 'Track mutual funds, stocks, gold, FDs…'
              : '${m.investments.length} holdings · ${inr(m.totalPortfolioValue)}',
          screen: const InvestmentsScreen(),
        ),
      ],
    );
  }
}
