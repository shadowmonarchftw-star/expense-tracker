class UserSettings {
  final String? id;
  final double salary;
  final String currency;
  final bool isDarkMode;
  final bool isBiometricEnabled;
  final String calendarSystem; // 'AD' or 'BS'

  UserSettings({
    this.id,
    required this.salary,
    this.currency = '\$',
    this.isDarkMode = false,
    this.isBiometricEnabled = false,
    this.calendarSystem = 'AD',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salary': salary,
      'currency': currency,
      'isDarkMode': isDarkMode ? 1 : 0,
      'isBiometricEnabled': isBiometricEnabled ? 1 : 0,
      'calendarSystem': calendarSystem,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id']?.toString(), // Handle parsing
      salary: map['salary'],
      currency: map['currency'] ?? '\$',
      isDarkMode: (map['isDarkMode'] == 1 || map['isDarkMode'] == true),
      isBiometricEnabled: (map['isBiometricEnabled'] == 1 || map['isBiometricEnabled'] == true),
      calendarSystem: map['calendarSystem'] ?? 'AD',
    );
  }
}
