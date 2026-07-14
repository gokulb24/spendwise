import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/pdf_report.dart';
import '../widgets/common.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  String _topCategory(AppModel m) {
    final s = m.summary;
    String top = '—';
    double max = 0;
    s.spentByCat.forEach((k, v) {
      if (v > max) {
        max = v;
        top = k;
      }
    });
    return max > 0 ? '$top (${inr(max)})' : '—';
  }

  String _topMember(AppModel m) {
    final s = m.summary;
    String top = '—';
    double max = 0;
    s.spentByMem.forEach((k, v) {
      if (v > max) {
        max = v;
        top = k;
      }
    });
    return max > 0 ? '$top (${inr(max)})' : '—';
  }

  Future<void> _download(BuildContext context) async {
    final m = context.read<AppModel>();
    try {
      await shareMonthlyReport(
        month: m.currentMonth,
        members: m.members,
        monthExpenses: m.monthExpenses,
        budgets: m.currentBudgets,
        summary: m.summary,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not create the PDF. $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final s = m.summary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text('Reports',
            style: context.texts.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(monthLabel(m.currentMonth),
            style: context.texts.bodyMedium
                ?.copyWith(color: context.scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Monthly Summary',
          child: Column(
            children: [
              _row(context, 'Total Income', inr(s.income)),
              _row(context, 'Total Spent', inr(s.totalSpent)),
              _row(context, 'Net Savings', inr(s.netSavings),
                  color: s.netSavings < 0
                      ? context.semantic.negative
                      : context.semantic.positive),
              _row(context, 'Budget', inr(s.totalBudget)),
              const Divider(height: 20),
              _row(context, 'Top Category', _topCategory(m)),
              _row(context, 'Top Spender', _topMember(m)),
              _row(context, 'Transactions', '${m.monthExpenses.length}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Monthly PDF Report',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'A polished PDF with your summary, category budget vs. actual, '
                  'spending by member and the full expense log.',
                  style: context.texts.bodyMedium
                      ?.copyWith(color: context.scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _download(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download / share PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
