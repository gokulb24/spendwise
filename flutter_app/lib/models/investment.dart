const List<String> kInvestmentTypes = [
  'Mutual Fund',
  'Stocks',
  'SIP',
  'Fixed Deposit',
  'PPF / EPF',
  'Gold',
  'Real Estate',
  'Bonds',
  'Crypto',
  'Other',
];

/// A holding/asset. Stored in `families/{id}/investments/{id}`.
class Investment {
  final String id;
  final String name;
  final String type;
  final double invested; // amount put in
  final double currentValue; // current worth
  final String date; // yyyy-MM-dd — started / last updated

  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.invested,
    required this.currentValue,
    required this.date,
  });

  double get returns => currentValue - invested;
  double get returnPct => invested > 0 ? (returns / invested * 100) : 0;
  bool get isGain => returns >= 0;

  factory Investment.fromMap(String id, Map<String, dynamic> m) => Investment(
        id: id,
        name: (m['name'] ?? 'Investment') as String,
        type: (m['type'] ?? 'Other') as String,
        invested: ((m['invested'] ?? 0) as num).toDouble(),
        currentValue: ((m['currentValue'] ?? 0) as num).toDouble(),
        date: (m['date'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'invested': invested,
        'currentValue': currentValue,
        'date': date,
      };
}
