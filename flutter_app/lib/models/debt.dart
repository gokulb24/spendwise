/// Loan / debt types tracked by the family.
const List<String> kDebtTypes = [
  'Home loan',
  'Gold loan',
  'Personal loan',
  'Car loan',
  'Education loan',
  'Credit card',
  'Business loan',
  'Other',
];

/// A single repayment towards a debt — records "when it was paid".
class DebtPayment {
  final String date; // yyyy-MM-dd
  final double amount;
  final String note;

  DebtPayment({required this.date, required this.amount, this.note = ''});

  factory DebtPayment.fromMap(Map<String, dynamic> m) => DebtPayment(
        date: (m['date'] ?? '') as String,
        amount: ((m['amount'] ?? 0) as num).toDouble(),
        note: (m['note'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'date': date,
        'amount': amount,
        if (note.isNotEmpty) 'note': note,
      };
}

/// A loan/debt. Stored in `families/{id}/debts/{id}`.
class Debt {
  final String id;
  final String name;
  final String type;
  final double principal; // total amount borrowed
  final double rate; // annual interest %, optional (0 = unknown)
  final double emi; // monthly EMI, optional (0 = none)
  final String startDate; // yyyy-MM-dd — when the loan was taken / disbursed
  final List<DebtPayment> payments;
  final bool closed;

  Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.principal,
    required this.rate,
    required this.emi,
    required this.startDate,
    required this.payments,
    required this.closed,
  });

  double get paid => payments.fold(0.0, (s, p) => s + p.amount);
  double get outstanding =>
      (principal - paid).clamp(0, double.infinity).toDouble();
  double get progress => principal > 0 ? (paid / principal).clamp(0, 1) : 0;
  bool get isFullyPaid => closed || outstanding <= 0;

  String? get lastPaymentDate => payments.isEmpty
      ? null
      : payments.map((p) => p.date).reduce((a, b) => a.compareTo(b) > 0 ? a : b);

  factory Debt.fromMap(String id, Map<String, dynamic> m) => Debt(
        id: id,
        name: (m['name'] ?? 'Loan') as String,
        type: (m['type'] ?? 'Other') as String,
        principal: ((m['principal'] ?? 0) as num).toDouble(),
        rate: ((m['rate'] ?? 0) as num).toDouble(),
        emi: ((m['emi'] ?? 0) as num).toDouble(),
        startDate: (m['startDate'] ?? '') as String,
        payments: ((m['payments'] as List?) ?? const [])
            .map((e) => DebtPayment.fromMap((e as Map).cast<String, dynamic>()))
            .toList(),
        closed: (m['closed'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'principal': principal,
        'rate': rate,
        'emi': emi,
        'startDate': startDate,
        'payments': payments.map((p) => p.toMap()).toList(),
        'closed': closed,
      };
}
