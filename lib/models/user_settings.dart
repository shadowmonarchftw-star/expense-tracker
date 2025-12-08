class UserSettings {
  final int? id;
  final double salary;
  final String currencyCode;

  UserSettings({
    this.id,
    required this.salary,
    this.currencyCode = 'NPR',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salary': salary,
      'currencyCode': currencyCode,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'],
      salary: map['salary'],
      currencyCode: map['currencyCode'] ?? 'NPR',
    );
  }
}
