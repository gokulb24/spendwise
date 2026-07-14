/// A savings goal or emergency fund. Stored in `families/{id}/goals/{id}`.
class Goal {
  final String id;
  final String name;
  final String type; // 'savings' | 'emergency'
  final double target;
  final double saved;
  final String? deadline; // yyyy-MM-dd, optional

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.saved,
    this.deadline,
  });

  double get progress => target > 0 ? (saved / target).clamp(0, 1) : 0;
  double get remaining => (target - saved).clamp(0, double.infinity);
  bool get isEmergency => type == 'emergency';

  factory Goal.fromMap(String id, Map<String, dynamic> m) => Goal(
        id: id,
        name: (m['name'] ?? 'Goal') as String,
        type: (m['type'] ?? 'savings') as String,
        target: ((m['target'] ?? 0) as num).toDouble(),
        saved: ((m['saved'] ?? 0) as num).toDouble(),
        deadline: m['deadline'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'target': target,
        'saved': saved,
        if (deadline != null) 'deadline': deadline,
      };
}
