import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Round [value] up to a clean axis maximum (1/2/2.5/5 × 10ⁿ).
double niceCeil(double value) {
  if (value <= 0) return 1000;
  final mag = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  final norm = value / mag; // 1..10
  final step = norm <= 1
      ? 1.0
      : norm <= 2
          ? 2.0
          : norm <= 2.5
              ? 2.5
              : norm <= 5
                  ? 5.0
                  : 10.0;
  return step * mag;
}

String _axisLabel(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '₹${k == k.roundToDouble() ? k.round() : k.toStringAsFixed(1)}k';
  }
  return '₹${v.round()}';
}

class CategoryChartCard extends StatelessWidget {
  const CategoryChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppModel>().summary;
    final scheme = context.scheme;
    // All categories that actually have spending (independent of the
    // configured category list), largest first.
    final entries = s.spentByCat.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SectionCard(
      title: 'Spending by Category',
      child: SizedBox(
        height: 230,
        child: entries.isEmpty
            ? Center(
                child: Text('No spending yet',
                    style: TextStyle(color: scheme.onSurfaceVariant)))
            : Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 46,
                        sections: [
                          for (var i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value,
                              color: kPalette[i % kPalette.length],
                              title: '',
                              radius: 34,
                            ),
                        ],
                      )),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < entries.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: kPalette[i % kPalette.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(entries[i].key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.texts.bodySmall),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class MemberChartCard extends StatelessWidget {
  const MemberChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final members = m.breakdownMembers;
    final s = m.summary;
    final values = [for (final mb in members) (s.spentByMem[mb] ?? 0).toDouble()];
    final rawMax = values.isEmpty ? 0.0 : values.reduce(math.max);
    final maxY = niceCeil(rawMax); // clean top so bars line up with labels
    final interval = maxY / 4; // exactly 5 gridlines (0..maxY)
    return SectionCard(
      title: 'Spending by Member',
      child: SizedBox(
        height: 230,
        child: members.isEmpty
            ? Center(
                child: Text('No members',
                    style: TextStyle(color: scheme.onSurfaceVariant)))
            : BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: [
                  for (var i = 0; i < members.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: kPalette[i % kPalette.length],
                        width: 18,
                        borderRadius: BorderRadius.circular(5),
                      )
                    ]),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (v) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 46,
                      getTitlesWidget: (v, meta) {
                        if (v > maxY + 0.5) return const SizedBox();
                        return Text(_axisLabel(v),
                            style: context.texts.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= members.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(members[i].split(' ').first,
                              style: context.texts.labelSmall),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      inr(rod.toY),
                      TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ),
                ),
              )),
      ),
    );
  }
}
