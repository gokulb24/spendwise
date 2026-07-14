import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/constants.dart';
import '../models/expense.dart';
import 'format.dart';
import 'summary.dart';

final _navy = PdfColor.fromInt(0xFF1F3A5F);
final _accent = PdfColor.fromInt(0xFF2E6F95);
final _zebra = PdfColor.fromInt(0xFFF2F7FB);
final _greyC = PdfColor.fromInt(0xFF6B7280);
final _slate = PdfColor.fromInt(0xFF334155);

/// Build the monthly report PDF and hand it to the OS share/print sheet
/// (from which the user can Save to Files / Drive, print, or share).
Future<void> shareMonthlyReport({
  required String month,
  required List<String> members,
  required List<Expense> monthExpenses,
  required Map<String, double> budgets,
  required MonthSummary summary,
}) async {
  final bytes = await buildMonthlyReport(
    month: month,
    members: members,
    monthExpenses: monthExpenses,
    budgets: budgets,
    summary: summary,
  );
  await Printing.sharePdf(bytes: bytes, filename: 'family-expenses-$month.pdf');
}

Future<Uint8List> buildMonthlyReport({
  required String month,
  required List<String> members,
  required List<Expense> monthExpenses,
  required Map<String, double> budgets,
  required MonthSummary summary,
}) async {
  final doc = pw.Document();
  final label = monthLabel(month);
  final generated = DateFormat('dd MMM yyyy').format(DateTime.now());

  final cards = <List<String>>[
    ['TOTAL BUDGET', rs(summary.totalBudget)],
    ['TOTAL SPENT', rs(summary.totalSpent)],
    ['REMAINING', rs(summary.remaining)],
    ['TOTAL INCOME', rs(summary.income)],
    ['NET SAVINGS', rs(summary.netSavings)],
  ];

  final sorted = [...monthExpenses]
    ..sort((a, b) => a.date.compareTo(b.date));

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 0, 28, 36),
      ),
      header: (ctx) => ctx.pageNumber == 1
          ? _headerBand(label, generated)
          : pw.SizedBox(height: 8),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('SpendWise',
                style: pw.TextStyle(fontSize: 8, color: _greyC)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: _greyC)),
          ],
        ),
      ),
      build: (ctx) => [
        pw.SizedBox(height: 14),
        _summaryCards(cards),
        pw.SizedBox(height: 20),
        _section('Category Budget vs. Actual'),
        _categoryTable(budgets, summary),
        pw.SizedBox(height: 18),
        _section('Spending by Member'),
        _memberTable(members, summary),
        pw.SizedBox(height: 18),
        _section('Expense Log (${sorted.length}'
            ' ${sorted.length == 1 ? 'entry' : 'entries'})'),
        _expenseTable(sorted),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _headerBand(String label, String generated) => pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.fromLTRB(28, 16, 28, 14),
      margin: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Family Expense Report',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$label  ·  INR',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 11)),
              pw.Text('Generated $generated',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 8)),
            ],
          ),
        ],
      ),
    );

pw.Widget _summaryCards(List<List<String>> cards) => pw.Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(cards[i][0],
                      style: pw.TextStyle(fontSize: 6.5, color: _greyC)),
                  pw.SizedBox(height: 6),
                  pw.Text(cards[i][1],
                      style: pw.TextStyle(
                          fontSize: 10.5,
                          color: _navy,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (i != cards.length - 1) pw.SizedBox(width: 8),
        ]
      ],
    );

pw.Widget _section(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12, color: _navy, fontWeight: pw.FontWeight.bold)),
    );

pw.Widget _categoryTable(Map<String, double> budgets, MonthSummary s) {
  final data = <List<String>>[];
  for (final c in kCategories) {
    final b = budgets[c] ?? 0;
    final sp = s.spentByCat[c] ?? 0;
    final pct = b > 0 ? (sp / b * 100).round() : 0;
    data.add([c, rs(b), rs(sp), rs(b - sp), '$pct%']);
  }
  final totalPct = s.catBudgetSum > 0
      ? (s.totalSpent / s.catBudgetSum * 100).round()
      : 0;
  return pw.TableHelper.fromTextArray(
    headers: ['Category', 'Budget', 'Spent', 'Left', '%'],
    data: [
      ...data,
      ['Total', rs(s.catBudgetSum), rs(s.totalSpent),
        rs(s.catBudgetSum - s.totalSpent), '$totalPct%'],
    ],
    headerStyle: pw.TextStyle(
        color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
    headerDecoration: pw.BoxDecoration(color: _accent),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellHeight: 18,
    oddRowDecoration: pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerRight,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerRight,
    },
  );
}

pw.Widget _memberTable(List<String> members, MonthSummary s) {
  final data = <List<String>>[];
  for (final m in members) {
    final sp = s.spentByMem[m] ?? 0;
    final share = s.totalSpent > 0 ? (sp / s.totalSpent * 100).round() : 0;
    data.add([m, rs(sp), '$share%']);
  }
  return pw.TableHelper.fromTextArray(
    headers: ['Member', 'Spent', 'Share'],
    data: [
      ...data,
      ['Total', rs(s.totalSpent), '100%'],
    ],
    headerStyle: pw.TextStyle(
        color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
    headerDecoration: pw.BoxDecoration(color: _accent),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellHeight: 18,
    oddRowDecoration: pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerRight,
      2: pw.Alignment.centerRight,
    },
  );
}

pw.Widget _expenseTable(List<Expense> sorted) {
  if (sorted.isEmpty) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text('No expenses recorded for this month.',
          style: pw.TextStyle(color: _slate, fontSize: 10)),
    );
  }
  return pw.TableHelper.fromTextArray(
    headers: ['Date', 'Description', 'Category', 'Member', 'Amount', 'Payment'],
    data: sorted
        .map((e) => [
              fmtDay(e.date),
              e.desc,
              e.cat,
              e.mem,
              rs(e.amt),
              e.pay,
            ])
        .toList(),
    headerStyle: pw.TextStyle(
        color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
    headerDecoration: pw.BoxDecoration(color: _accent),
    cellStyle: const pw.TextStyle(fontSize: 8.5),
    cellHeight: 16,
    oddRowDecoration: pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerLeft,
      4: pw.Alignment.centerRight,
      5: pw.Alignment.centerLeft,
    },
  );
}
