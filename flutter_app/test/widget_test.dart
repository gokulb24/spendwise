import 'package:flutter_test/flutter_test.dart';
import 'package:family_expense_tracker/models/expense.dart';
import 'package:family_expense_tracker/utils/summary.dart';
import 'package:family_expense_tracker/utils/format.dart';
import 'package:family_expense_tracker/models/recurring.dart';
import 'package:family_expense_tracker/models/goal.dart';
import 'package:family_expense_tracker/models/debt.dart';
import 'package:family_expense_tracker/widgets/charts.dart';
import 'package:family_expense_tracker/models/investment.dart';

void main() {
  group('MonthSummary.compute', () {
    final members = ['A', 'B'];
    final budgets = {'Groceries': 1000.0, 'Dining Out': 500.0};
    final expenses = [
      Expense(id: '1', date: '2026-07-02', desc: 'x', cat: 'Groceries', mem: 'A', amt: 300, pay: 'UPI'),
      Expense(id: '2', date: '2026-07-03', desc: 'y', cat: 'Dining Out', mem: 'B', amt: 200, pay: 'Cash'),
    ];

    test('totals, remaining, income and savings add up', () {
      final s = MonthSummary.compute(
        monthExpenses: expenses,
        members: members,
        budgets: budgets,
        incomeByMember: {'A': 5000, 'B': 3000},
      );
      expect(s.totalSpent, 500);
      expect(s.spentByCat['Groceries'], 300);
      expect(s.spentByMem['B'], 200);
      expect(s.income, 8000);
      expect(s.netSavings, 7500);
      // catBudgetSum spans all 15 categories (missing ones default to 0)
      expect(s.catBudgetSum, 1500);
      expect(s.hasOverride, false);
      expect(s.totalBudget, 1500);
      expect(s.remaining, 1000);
    });

    test('override replaces the category-sum budget', () {
      final s = MonthSummary.compute(
        monthExpenses: expenses,
        members: members,
        budgets: budgets,
        incomeByMember: const {},
        totalOverride: 900,
      );
      expect(s.hasOverride, true);
      expect(s.totalBudget, 900);
      expect(s.remaining, 400);
    });
  });

  group('month helpers', () {
    test('addMonths rolls over the year', () {
      expect(addMonths('2026-11', 3), '2027-02');
      expect(addMonths('2026-03', -1), '2026-02');
    });
    test('financial-year end is the following March', () {
      expect(fyEndYm('2026-07'), '2027-03');
      expect(fyEndYm('2026-02'), '2026-03');
    });
    test('buildMonths is newest-first and includes expense months', () {
      final months = buildMonths('2026-07', ['2026-09']);
      expect(months.first.compareTo(months.last) >= 0, true);
      expect(months.contains('2026-09'), true);
    });
    test('ymStr extracts the yyyy-MM prefix', () {
      expect(ymStr('2026-07-15'), '2026-07');
    });
  });

  group('Recurring.advance', () {
    test('advances by each frequency', () {
      expect(Recurring.advance('2026-07-15', 'daily'), '2026-07-16');
      expect(Recurring.advance('2026-07-15', 'weekly'), '2026-07-22');
      expect(Recurring.advance('2026-07-15', 'monthly'), '2026-08-15');
      expect(Recurring.advance('2026-07-15', 'quarterly'), '2026-10-15');
      expect(Recurring.advance('2026-07-15', 'yearly'), '2027-07-15');
    });
    test('monthly rolls over the year', () {
      expect(Recurring.advance('2026-12-10', 'monthly'), '2027-01-10');
    });
  });

  group('Goal progress', () {
    test('progress and remaining compute correctly', () {
      final g = Goal(id: '1', name: 'Car', type: 'savings', target: 1000, saved: 250);
      expect(g.progress, 0.25);
      expect(g.remaining, 750);
    });
    test('progress clamps at 1 when over-saved', () {
      final g = Goal(id: '1', name: 'X', type: 'emergency', target: 100, saved: 300);
      expect(g.progress, 1.0);
      expect(g.remaining, 0);
    });
  });


  group('Debt', () {
    Debt d(List<DebtPayment> p) => Debt(id: '1', name: 'Home', type: 'Home loan',
        principal: 100000, rate: 8, emi: 5000, startDate: '2026-01-01',
        payments: p, closed: false);
    test('outstanding, paid and progress', () {
      final x = d([DebtPayment(date: '2026-02-01', amount: 20000),
                   DebtPayment(date: '2026-03-01', amount: 30000)]);
      expect(x.paid, 50000);
      expect(x.outstanding, 50000);
      expect(x.progress, 0.5);
      expect(x.lastPaymentDate, '2026-03-01');
    });
    test('outstanding never goes negative and progress clamps', () {
      final x = d([DebtPayment(date: '2026-02-01', amount: 150000)]);
      expect(x.outstanding, 0);
      expect(x.progress, 1.0);
      expect(x.isFullyPaid, true);
    });
  });


  group('niceCeil (bar chart axis)', () {
    test('rounds up to clean maxima so bars line up', () {
      expect(niceCeil(8500), 10000);   // >8k no longer mismatches
      expect(niceCeil(7000), 10000);
      expect(niceCeil(4200), 5000);
      expect(niceCeil(1800), 2000);
      expect(niceCeil(230), 250);
      expect(niceCeil(0), 1000);
    });
    test('maxY divides evenly into 4 gridline intervals', () {
      for (final v in [8500.0, 4200.0, 12345.0, 999.0]) {
        final maxY = niceCeil(v);
        expect(maxY >= v, true);
        expect((maxY / 4) * 4, maxY);
      }
    });
  });

  group('Investment', () {
    test('returns and percentage', () {
      final i = Investment(id: '1', name: 'MF', type: 'Mutual Fund',
          invested: 100000, currentValue: 125000, date: '2026-01-01');
      expect(i.returns, 25000);
      expect(i.returnPct, 25.0);
      expect(i.isGain, true);
    });
    test('a loss is reported as negative', () {
      final i = Investment(id: '1', name: 'X', type: 'Stocks',
          invested: 100000, currentValue: 80000, date: '2026-01-01');
      expect(i.returns, -20000);
      expect(i.isGain, false);
    });
  });

}
