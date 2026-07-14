import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

class MemberTable extends StatelessWidget {
  const MemberTable({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final s = m.summary;
    return SectionCard(
      title: 'Spending by Member',
      child: Column(
        children: [
          for (final mb in m.breakdownMembers)
            _row(context, mb, s.spentByMem[mb] ?? 0, s.totalSpent),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                  child: Text('Total',
                      style: context.texts.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700))),
              Text(inr(s.totalSpent),
                  style: context.texts.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String name, double spent, double total) {
    final scheme = context.scheme;
    final share = total > 0 ? (spent / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.texts.bodyMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(inr(spent),
                textAlign: TextAlign.right, style: context.texts.bodyMedium),
          ),
          SizedBox(
            width: 44,
            child: Text('${(share * 100).round()}%',
                textAlign: TextAlign.right,
                style: context.texts.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
