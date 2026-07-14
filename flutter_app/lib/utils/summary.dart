import '../data/constants.dart';
import '../models/expense.dart';
import 'format.dart';

/// Pure, testable aggregation of one month's numbers.
class MonthSummary {
  final Map<String, double> spentByCat;
  final Map<String, double> spentByMem;
  final double totalSpent;
  final double catBudgetSum;
  final double totalBudget;
  final bool hasOverride;
  final double remaining;
  final double income;
  final double netSavings;

  MonthSummary({
    required this.spentByCat,
    required this.spentByMem,
    required this.totalSpent,
    required this.catBudgetSum,
    required this.totalBudget,
    required this.hasOverride,
    required this.remaining,
    required this.income,
    required this.netSavings,
  });

  static MonthSummary compute({
    required List<Expense> monthExpenses,
    required List<String> members,
    required Map<String, double> budgets,
    required Map<String, double> incomeByMember,
    List<String> categories = kCategories,
    double? totalOverride,
  }) {
    final spentByCat = {for (final c in categories) c: 0.0};
    final spentByMem = {for (final m in members) m: 0.0};
    var totalSpent = 0.0;
    for (final e in monthExpenses) {
      spentByCat[e.cat] = (spentByCat[e.cat] ?? 0) + e.amt;
      spentByMem[e.mem] = (spentByMem[e.mem] ?? 0) + e.amt;
      totalSpent += e.amt;
    }
    final catSum =
        categories.fold<double>(0, (s, c) => s + (budgets[c] ?? 0));
    final hasOverride = totalOverride != null;
    final totalBudget = hasOverride ? totalOverride : catSum;
    final income =
        members.fold<double>(0, (s, m) => s + (incomeByMember[m] ?? 0));
    return MonthSummary(
      spentByCat: spentByCat,
      spentByMem: spentByMem,
      totalSpent: totalSpent,
      catBudgetSum: catSum,
      totalBudget: totalBudget,
      hasOverride: hasOverride,
      remaining: totalBudget - totalSpent,
      income: income,
      netSavings: income - totalSpent,
    );
  }

  String get totalSpentText => inr(totalSpent);
  String get remainingText => inr(remaining);
  String get incomeText => inr(income);
  String get netSavingsText => inr(netSavings);
  String get totalBudgetText => inr(totalBudget);
  double get usedPct =>
      totalBudget > 0 ? (totalSpent / totalBudget * 100).clamp(0, 100) : 0;
}
