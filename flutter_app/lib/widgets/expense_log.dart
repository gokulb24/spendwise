import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'expense_tile.dart';

/// Recent transactions card for the dashboard.
class ExpenseLog extends StatelessWidget {
  final int limit;
  final VoidCallback? onSeeAll;
  const ExpenseLog({super.key, this.limit = 5, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final items = [...m.monthExpenses]
      ..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.id.compareTo(a.id);
      });
    final shown = items.take(limit).toList();
    return SectionCard(
      title: 'Recent Transactions',
      trailing: (onSeeAll != null && items.length > limit)
          ? TextButton(onPressed: onSeeAll, child: const Text('See all'))
          : null,
      child: shown.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No expenses this month yet.',
                    style: TextStyle(color: context.scheme.onSurfaceVariant)),
              ),
            )
          : Column(
              children: [
                for (final e in shown) ExpenseListItem(e: e, dense: true),
              ],
            ),
    );
  }
}
