import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/budget_table.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/expense_log.dart';
import '../widgets/income_section.dart';
import '../widgets/kpi_cards.dart';
import '../widgets/member_table.dart';
import '../widgets/month_picker.dart';
import 'ai_assistant_screen.dart';
import 'debts_screen.dart';

class DashboardTab extends StatelessWidget {
  final VoidCallback? onSeeAllExpenses;
  const DashboardTab({super.key, this.onSeeAllExpenses});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    return RefreshIndicator(
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 400)),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 720;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(m: m)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList.list(children: [
                const _HealthScoreCard(),
                const SizedBox(height: 14),
                const _AiCard(),
                const SizedBox(height: 14),
                const KpiCards(),
                if (m.debts.any((d) => !d.isFullyPaid)) ...[
                  const SizedBox(height: 14),
                  const _DebtSummaryCard(),
                ],
                const SizedBox(height: 14),
                const IncomeSection(),
                const SizedBox(height: 14),
                _pair(wide, const CategoryChartCard(), const MemberChartCard()),
                const SizedBox(height: 14),
                _pair(wide, const BudgetTable(), const MemberTable()),
                const SizedBox(height: 14),
                ExpenseLog(onSeeAll: onSeeAllExpenses),
              ]),
            ),
          ],
        );
      }),
    );
  }

  Widget _pair(bool wide, Widget a, Widget b) {
    if (!wide) {
      return Column(children: [a, const SizedBox(height: 14), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 14),
        Expanded(child: b),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final AppModel m;
  const _Header({required this.m});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final name = (m.user?.displayName?.trim().isNotEmpty ?? false)
        ? m.user!.displayName!.split(' ').first
        : 'there';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $name 👋',
                        style: context.texts.titleLarge?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700)),
                    Text(m.family?.name ?? 'Your family',
                        style: context.texts.bodyMedium?.copyWith(
                            color: scheme.onPrimary.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _MonthSelector(),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard();
  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final scheme = context.scheme;
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
                value: m, child: const AiAssistantScreen()))),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.tertiaryContainer, scheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: scheme.onPrimaryContainer, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Assistant',
                          style: context.texts.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer)),
                      Text('Summarise this month or ask about your money',
                          style: context.texts.bodySmall?.copyWith(
                              color: scheme.onPrimaryContainer
                                  .withValues(alpha: 0.9))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard();
  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final active = m.debts.where((d) => !d.isFullyPaid).length;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
                value: m, child: const DebtsScreen()))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.account_balance_outlined,
                    color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Debt outstanding',
                        style: context.texts.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(inr(m.totalOutstanding),
                        style: context.texts.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Text('$active active',
                  style: context.texts.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector();
  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    return Material(
      color: scheme.onPrimary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showMonthPicker(context, m.currentMonth);
          if (picked != null) m.setMonth(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 20, color: scheme.onPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(monthLabel(m.currentMonth),
                    style: context.texts.titleMedium
                        ?.copyWith(color: scheme.onPrimary)),
              ),
              Icon(Icons.expand_more, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple, transparent "financial health" gauge derived from the current
/// month's savings rate and budget adherence. (Heuristic, not advice.)
class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard();

  int _score(AppModel m) {
    final s = m.summary;
    var score = 50.0;
    if (s.income > 0) {
      final savingsRate = s.netSavings / s.income; // -inf..1
      score += savingsRate.clamp(-1, 1) * 35;
    }
    if (s.totalBudget > 0) {
      final overshoot = (s.totalSpent - s.totalBudget) / s.totalBudget;
      score -= overshoot.clamp(0, 1) * 25;
    }
    return score.clamp(0, 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final sem = context.semantic;
    final score = _score(m);
    final color = score >= 70
        ? sem.positive
        : score >= 40
            ? sem.warning
            : sem.negative;
    final label = score >= 70
        ? 'Healthy'
        : score >= 40
            ? 'Watch spending'
            : 'Over budget';
    return SectionCard(
      title: 'Financial Health',
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
                Text('$score',
                    style: context.texts.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: context.texts.titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    'Based on this month\'s savings rate and how close you are '
                    'to your total budget.',
                    style: context.texts.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
