import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class KpiCards extends StatelessWidget {
  const KpiCards({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final s = m.summary;
    final sem = context.semantic;
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? 4 : 2;
      final cards = [
        _KpiTile(
            label: 'Total Budget',
            value: inr(s.totalBudget),
            icon: Icons.account_balance_wallet_outlined),
        _KpiTile(
            label: 'Total Spent',
            value: inr(s.totalSpent),
            icon: Icons.payments_outlined,
            barPct: s.usedPct.toDouble()),
        _KpiTile(
            label: 'Remaining',
            value: inr(s.remaining),
            icon: Icons.savings_outlined,
            valueColor: s.remaining < 0 ? sem.negative : null),
        _KpiTile(
            label: 'Net Savings',
            value: inr(s.netSavings),
            icon: Icons.trending_up,
            valueColor: s.netSavings < 0 ? sem.negative : sem.positive),
      ];
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 112,
        ),
        children: cards,
      );
    });
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final double? barPct;
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.barPct,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final sem = context.semantic;
    final barColor = (barPct ?? 0) >= 100
        ? sem.negative
        : (barPct ?? 0) >= 80
            ? sem.warning
            : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3)),
              ),
            ],
          ),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? scheme.onSurface)),
          if (barPct != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (barPct! / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: barColor,
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}
