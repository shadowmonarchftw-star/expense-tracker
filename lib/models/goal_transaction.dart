class GoalTransaction {
  final String? id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? notes;

  GoalTransaction({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory GoalTransaction.fromMap(Map<String, dynamic> map) {
    return GoalTransaction(
      id: map['id']?.toString(),
      goalId: map['goalId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  GoalTransaction copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return GoalTransaction(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
