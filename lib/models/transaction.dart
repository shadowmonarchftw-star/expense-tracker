class Transaction {
  final String? id;
  final DateTime timestamp;
  final double amount;
  final String category;
  final String subCategory; // New field for sub-category
  final String type; // 'income' or 'expense'
  final String note;

  Transaction({
    this.id,
    required this.timestamp,
    required this.amount,
    required this.category,
    this.subCategory = '', // Default to empty string
    required this.type,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'category': category,
      'subCategory': subCategory,
      'type': type,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString(),
      timestamp: DateTime.parse(map['timestamp']),
      amount: map['amount'],
      category: map['category'],
      subCategory: map['subCategory'] ?? '',
      type: map['type'],
      note: map['note'] ?? '',
    );
  }
  Transaction copyWith({
    String? id,
    DateTime? timestamp,
    double? amount,
    String? category,
    String? subCategory,
    String? type,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
