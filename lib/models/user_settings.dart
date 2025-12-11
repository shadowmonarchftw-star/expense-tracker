class UserSettings {
  final String? id;
  final double salary;
  final String currency;
  final bool isDarkMode;
  final bool isBiometricEnabled;
  final String calendarSystem; // 'AD' or 'BS'
  final bool isDailyReminderEnabled;

  UserSettings({
    this.id,
    required this.salary,
    this.currency = '\$',
    this.isDarkMode = false,
    this.isBiometricEnabled = false,
    this.calendarSystem = 'AD',
    this.isDailyReminderEnabled = false, // Default off
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salary': salary,
      'currency': currency,
      'isDarkMode': isDarkMode ? 1 : 0,
      'isBiometricEnabled': isBiometricEnabled ? 1 : 0,
      'calendarSystem': calendarSystem,
      'isDailyReminderEnabled': isDailyReminderEnabled ? 1 : 0,
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
      isDailyReminderEnabled: (map['isDailyReminderEnabled'] == 1 || map['isDailyReminderEnabled'] == true),
    );
  }
}
