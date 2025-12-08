class FixedExpense {
  final int? id;
  final String name;
  final double amount;

  FixedExpense({
    this.id,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
    };
  }

  factory FixedExpense.fromMap(Map<String, dynamic> map) {
    return FixedExpense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
    );
  }
}
