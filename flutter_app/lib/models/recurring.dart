import '../utils/format.dart';

const List<String> kFrequencies = [
  'daily',
  'weekly',
  'monthly',
  'quarterly',
  'yearly',
];

/// A template that auto-generates expenses on a schedule.
/// Stored in `families/{id}/recurring/{id}`.
class Recurring {
  final String id;
  final String desc;
  final String cat;
  final String mem;
  final double amt;
  final String pay;
  final String frequency; // one of kFrequencies
  final String nextDate; // yyyy-MM-dd — next occurrence to generate
  final bool active;

  Recurring({
    required this.id,
    required this.desc,
    required this.cat,
    required this.mem,
    required this.amt,
    required this.pay,
    required this.frequency,
    required this.nextDate,
    required this.active,
  });

  factory Recurring.fromMap(String id, Map<String, dynamic> m) => Recurring(
        id: id,
        desc: (m['desc'] ?? '') as String,
        cat: (m['cat'] ?? '') as String,
        mem: (m['mem'] ?? '') as String,
        amt: ((m['amt'] ?? 0) as num).toDouble(),
        pay: (m['pay'] ?? '') as String,
        frequency: (m['frequency'] ?? 'monthly') as String,
        nextDate: (m['nextDate'] ?? todayIso()) as String,
        active: (m['active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'desc': desc,
        'cat': cat,
        'mem': mem,
        'amt': amt,
        'pay': pay,
        'frequency': frequency,
        'nextDate': nextDate,
        'active': active,
      };

  /// The date after [from] (yyyy-MM-dd) for this frequency.
  static String advance(String from, String frequency) {
    final d = DateTime.parse(from);
    late DateTime n;
    switch (frequency) {
      case 'daily':
        n = d.add(const Duration(days: 1));
        break;
      case 'weekly':
        n = d.add(const Duration(days: 7));
        break;
      case 'quarterly':
        n = DateTime(d.year, d.month + 3, d.day);
        break;
      case 'yearly':
        n = DateTime(d.year + 1, d.month, d.day);
        break;
      case 'monthly':
      default:
        n = DateTime(d.year, d.month + 1, d.day);
        break;
    }
    return ymd(n);
  }
}
