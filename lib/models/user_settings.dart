class UserSettings {
  final String? id;
  final double salary;
  final String currency;
  final bool isDarkMode;

  UserSettings({
    this.id,
    required this.salary,
    this.currency = '\$',
    this.isDarkMode = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salary': salary,
      'currency': currency,
      'isDarkMode': isDarkMode ? 1 : 0,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id']?.toString(), // Handle parsing
      salary: map['salary'],
      currency: map['currency'] ?? '\$',
      isDarkMode: (map['isDarkMode'] == 1 || map['isDarkMode'] == true),
    );
  }
}
