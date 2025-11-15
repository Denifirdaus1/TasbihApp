import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/app_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    tz.initializeTimeZones();
    
    // Request notification permission for Android 13+
    await requestNotificationPermission();
  }

  static Future<bool> requestNotificationPermission() async {
    if (_plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (_plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestExactAlarmsPermission();
      return granted ?? false;
    }
    return true;
  }

  static Future<void> showCelebration(String title, String body) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smarttasbih-celebration',
          'SmartTasbih Celebration',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String message,
  }) async {
    await cancelReminder();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      AppConfig.smartReminderNotificationId,
      'Pengingat Smart Tasbih',
      message,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smarttasbih-reminder',
          'SmartTasbih Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancel(AppConfig.smartReminderNotificationId);
  }

  static Future<void> scheduleCollectionReminder({
    required String collectionId,
    required String collectionName,
    required TimeOfDay time,
    required String message,
  }) async {
    final notificationId = collectionId.hashCode;
    
    await _plugin.cancel(notificationId);
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      'Pengingat: $collectionName',
      message,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasbih-collection-reminder',
          'Pengingat Koleksi Tasbih',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelCollectionReminder(String collectionId) async {
    final notificationId = collectionId.hashCode;
    await _plugin.cancel(notificationId);
  }

  static Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }
}
