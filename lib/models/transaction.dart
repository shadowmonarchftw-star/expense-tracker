class Transaction {
  final int? id;
  final DateTime timestamp;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final String note;

  Transaction({
    this.id,
    required this.timestamp,
    required this.amount,
    required this.category,
    required this.type,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'category': category,
      'type': type,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      amount: map['amount'],
      category: map['category'],
      type: map['type'],
      note: map['note'] ?? '',
    );
  }
}
