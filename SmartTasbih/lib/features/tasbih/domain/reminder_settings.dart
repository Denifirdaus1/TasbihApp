import 'package:flutter/material.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.id,
    required this.userId,
    required this.collectionId,
    required this.isEnabled,
    this.scheduledTime,
    this.prayerTime,
    this.customMessage,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String collectionId;
  final bool isEnabled;
  final TimeOfDay? scheduledTime;
  final String? prayerTime;
  final String? customMessage;
  final List<int> daysOfWeek;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    TimeOfDay? time;
    if (map['scheduled_time'] != null) {
      final timeStr = map['scheduled_time'] as String;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    return ReminderSettings(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      collectionId: map['collection_id'] as String,
      isEnabled: (map['is_enabled'] as bool?) ?? true,
      scheduledTime: time,
      prayerTime: map['prayer_time'] as String?,
      customMessage: map['custom_message'] as String?,
      daysOfWeek: map['days_of_week'] != null
          ? (map['days_of_week'] as List).cast<int>()
          : [1, 2, 3, 4, 5, 6, 7],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'collection_id': collectionId,
      'is_enabled': isEnabled,
      'scheduled_time': scheduledTime != null
          ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'prayer_time': prayerTime,
      'custom_message': customMessage,
      'days_of_week': daysOfWeek,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  ReminderSettings copyWith({
    bool? isEnabled,
    TimeOfDay? scheduledTime,
    String? customMessage,
    List<int>? daysOfWeek,
  }) {
    return ReminderSettings(
      id: id,
      userId: userId,
      collectionId: collectionId,
      isEnabled: isEnabled ?? this.isEnabled,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      prayerTime: prayerTime,
      customMessage: customMessage ?? this.customMessage,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayMessage {
    if (customMessage != null && customMessage!.isNotEmpty) {
      return customMessage!;
    }
    return 'Waktunya dzikir! Jangan lupa untuk berdzikir hari ini.';
  }
}
