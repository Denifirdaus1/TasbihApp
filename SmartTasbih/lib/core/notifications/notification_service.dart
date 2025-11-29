import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/app_config.dart';
import '../utils/local_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _currentTimezone;

  static Future<void> initialize() async {
    if (_initialized) return;
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
    final timeZoneName = await LocalTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _currentTimezone = timeZoneName;
      if (kDebugMode) {
        debugPrint('[NotificationService] Timezone initialized: $timeZoneName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] Failed to set timezone $timeZoneName. Fallback UTC. Error: $e',
        );
      }
      tz.setLocalLocation(tz.getLocation('UTC'));
      _currentTimezone = 'UTC';
    }

    // Request notification permission for Android 13+
    await requestNotificationPermission();
    _initialized = true;
  }

  static Future<bool> requestNotificationPermission() async {
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() !=
        null) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() !=
        null) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
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
    final scheduledDate = _nextInstance(time);
    if (kDebugMode) {
      debugPrint(
        '[NotificationService] scheduleDailyReminder at $scheduledDate (now: ${tz.TZDateTime.now(tz.local)}, tz: $_currentTimezone)',
      );
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
    List<int>? daysOfWeek,
  }) async {
    final targetDays = (daysOfWeek == null || daysOfWeek.isEmpty)
        ? [1, 2, 3, 4, 5, 6, 7]
        : daysOfWeek;

    await cancelCollectionReminder(collectionId);

    for (final day in targetDays.toSet()) {
      final scheduledDate = _nextInstanceForDay(time, day);
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] scheduleCollectionReminder collection=$collectionId day=$day time=$scheduledDate (now: ${tz.TZDateTime.now(tz.local)}, tz: $_currentTimezone)',
        );
      }
      await _plugin.zonedSchedule(
        _collectionNotificationId(collectionId, day),
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> cancelCollectionReminder(String collectionId) async {
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(_collectionNotificationId(collectionId, day));
    }
  }

  static Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  static int _collectionNotificationId(String collectionId, int day) {
    return collectionId.hashCode ^ (day * 31);
  }

  static tz.TZDateTime _nextInstanceForDay(TimeOfDay time, int targetWeekday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static tz.TZDateTime _nextInstance(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
