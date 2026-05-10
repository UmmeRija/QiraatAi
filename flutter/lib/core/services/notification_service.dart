import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'dart:io'; // ✅ ADDED

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ✅ ADDED: Sirf Android aur iOS pe kaam karega
  bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_isSupported) return; // ✅ CHANGED: kIsWeb ki jagah _isSupported
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> schedulePrayerNotifications() async {
    if (!_isSupported) return; // ✅ CHANGED: kIsWeb ki jagah _isSupported

    await _notificationsPlugin.cancelAll();

    final prayerTimes = {
      'Fajr': {'hour': 5, 'minute': 0, 'message': 'It\'s time for Fajr... Remember to recite Surah Yaseen and Surah Fajr!'},
      'Zuhr': {'hour': 13, 'minute': 30, 'message': 'It\'s time for Zuhr... Remember to recite Surah Fatah.'},
      'Asr': {'hour': 17, 'minute': 0, 'message': 'It\'s time for Asr... Remember to recite Surah Naba.'},
      'Maghrib': {'hour': 19, 'minute': 15, 'message': 'It\'s time for Maghrib... Remember to recite Surah Waqiah and Surah Muzammil.'},
      'Isha': {'hour': 21, 'minute': 0, 'message': 'It\'s time for Isha... Recite Surah Mulk before sleep.'},
    };

    int id = 0;
    for (var entry in prayerTimes.entries) {
      await _scheduleDailyNotification(
        id++,
        'Prayer Time: ${entry.key}',
        entry.value['message'] as String,
        entry.value['hour'] as int,
        entry.value['minute'] as int,
      );
    }
  }

  Future<void> _scheduleDailyNotification(
      int id, String title, String body, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer Reminders',
          channelDescription: 'Notifications for daily prayer times',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showInstantNotification(String title, String body) async {
    if (!_isSupported) return; // ✅ CHANGED: kIsWeb ki jagah _isSupported

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}