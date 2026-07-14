/// A single expense entry. In cloud mode [id] is the Firestore document id.
class Expense {
  final String id;
  final String date; // yyyy-MM-dd
  final String desc;
  final String cat;
  final String mem;
  final double amt;
  final String pay;
  final String? by; // uid of the member who added it
  final List<String> tags;
  final String note;

  Expense({
    required this.id,
    required this.date,
    required this.desc,
    required this.cat,
    required this.mem,
    required this.amt,
    required this.pay,
    this.by,
    this.tags = const [],
    this.note = '',
  });

  factory Expense.fromMap(String id, Map<String, dynamic> m) => Expense(
        id: id,
        date: (m['date'] ?? '') as String,
        desc: (m['desc'] ?? '') as String,
        cat: (m['cat'] ?? '') as String,
        mem: ((m['mem'] ?? '') as String).trim(),
        amt: ((m['amt'] ?? 0) as num).toDouble(),
        pay: (m['pay'] ?? '') as String,
        by: m['by'] as String?,
        tags: ((m['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        note: (m['note'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'date': date,
        'desc': desc,
        'cat': cat,
        'mem': mem,
        'amt': amt,
        'pay': pay,
        if (by != null) 'by': by,
        'tags': tags,
        'note': note,
      };
}
