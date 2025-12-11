import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones(); // Initialize timezones

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings just in case
    final fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID for the daily reminder
      'Daily Reminder',
      'Don\'t forget to record your expenses for today!',
      _nextInstanceOf8PM(),
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminds you to record daily transactions',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time, // Repeats daily at same time
    );
  }

  Future<void> cancelDailyReminder() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  tz.TZDateTime _nextInstanceOf8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20); // 8 PM = 20:00
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
