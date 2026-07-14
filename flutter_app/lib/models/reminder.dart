/// A reminder that fires a local notification (e.g. "Buy groceries today").
/// Stored in `families/{id}/reminders/{id}`.
class Reminder {
  final String id;
  final String title;
  final String note;
  final String date; // yyyy-MM-dd
  final int hour;
  final int minute;
  final bool done;

  Reminder({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.hour,
    required this.minute,
    required this.done,
  });

  DateTime get dateTime {
    final d = DateTime.tryParse(date) ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  bool get isOverdue => !done && dateTime.isBefore(DateTime.now());
  bool get isPending => !done && !dateTime.isBefore(DateTime.now());

  factory Reminder.fromMap(String id, Map<String, dynamic> m) => Reminder(
        id: id,
        title: (m['title'] ?? '') as String,
        note: (m['note'] ?? '') as String,
        date: (m['date'] ?? '') as String,
        hour: ((m['hour'] ?? 9) as num).toInt(),
        minute: ((m['minute'] ?? 0) as num).toInt(),
        done: (m['done'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'note': note,
        'date': date,
        'hour': hour,
        'minute': minute,
        'done': done,
      };
}
