import 'package:intl/intl.dart';

final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

/// ₹ formatting for on-screen use.
String inr(num? n) => '₹${_inr.format((n ?? 0).round())}';

/// "Rs" formatting for PDFs (the built-in PDF font lacks the ₹ glyph).
String rs(num? n) => 'Rs ${_inr.format((n ?? 0).round())}';

/// YYYY-MM key for a date.
String ym(DateTime d) => DateFormat('yyyy-MM').format(d);

/// YYYY-MM key for an ISO date string (yyyy-MM-dd).
String ymStr(String isoDate) =>
    isoDate.length >= 7 ? isoDate.substring(0, 7) : isoDate;

/// Today as yyyy-MM-dd.
String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// yyyy-MM-dd for any DateTime.
String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// "01 Jul" short day label from an ISO date.
String fmtDay(String isoDate) {
  try {
    final d = DateTime.parse(isoDate);
    return DateFormat('dd MMM').format(d);
  } catch (_) {
    return isoDate;
  }
}

/// "July 2026" from a yyyy-MM key.
String monthLabel(String ymKey) {
  try {
    final d = DateTime.parse('$ymKey-01');
    return DateFormat('MMMM yyyy').format(d);
  } catch (_) {
    return ymKey;
  }
}

/// Add [n] months to a yyyy-MM key, returning yyyy-MM.
String addMonths(String ymKey, int n) {
  final parts = ymKey.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = DateTime(y, m + n, 1);
  return DateFormat('yyyy-MM').format(d);
}

/// The financial-year-end month (March) for a given base yyyy-MM.
String fyEndYm(String base) {
  final parts = base.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final endYear = m >= 4 ? y + 1 : y;
  return '$endYear-03';
}

/// The list of selectable months: current month → end of financial year,
/// plus any month that already has expenses, plus [currentMonth].
/// Newest first.
List<String> buildMonths(String currentMonth, Iterable<String> expenseMonths) {
  final base = ym(DateTime.now());
  final set = <String>{base, currentMonth};
  var m = base;
  final end = fyEndYm(base);
  var guard = 0;
  while (m.compareTo(end) <= 0 && guard++ < 36) {
    set.add(m);
    m = addMonths(m, 1);
  }
  for (final em in expenseMonths) {
    if (em.compareTo(base) >= 0) set.add(em);
  }
  final list = set
      .where((x) => x.compareTo(base) >= 0 || x == currentMonth)
      .toList()
    ..sort((a, b) => b.compareTo(a));
  return list;
}

/// Generate a 6-char invite code (unambiguous alphabet).
String generateInviteCode([int seed = 0]) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  // Deterministic-ish from microseconds; good enough for a family invite.
  var v = DateTime.now().microsecondsSinceEpoch ^ (seed * 2654435761);
  final sb = StringBuffer();
  for (var i = 0; i < 6; i++) {
    v = (v * 1103515245 + 12345) & 0x7fffffff;
    sb.write(alphabet[v % alphabet.length]);
  }
  return sb.toString();
}
