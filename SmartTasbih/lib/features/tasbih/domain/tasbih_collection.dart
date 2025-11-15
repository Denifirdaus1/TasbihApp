enum TasbihCollectionType {
  free('free'),
  prayerTimes('prayer_times'),
  timeBased('time_based');

  const TasbihCollectionType(this.value);
  final String value;

  static TasbihCollectionType fromString(String value) {
    return TasbihCollectionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TasbihCollectionType.free,
    );
  }
}

enum TimePeriod {
  pagi('pagi'),
  petang('petang');

  const TimePeriod(this.value);
  final String value;

  static TimePeriod fromString(String value) {
    return TimePeriod.values.firstWhere(
      (period) => period.value == value,
      orElse: () => TimePeriod.pagi,
    );
  }

  TimePeriod toggle() {
    return this == TimePeriod.pagi ? TimePeriod.petang : TimePeriod.pagi;
  }

  String get displayName {
    switch (this) {
      case TimePeriod.pagi:
        return 'Pagi';
      case TimePeriod.petang:
        return 'Petang';
    }
  }
}

enum TasbihGoalType {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const TasbihGoalType(this.value);
  final String value;

  static TasbihGoalType fromString(String value) {
    return TasbihGoalType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TasbihGoalType.daily,
    );
  }
}

class TasbihCollection {
  const TasbihCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.description,
    this.isDefault = false,
    this.color = '#4CAF50',
    this.icon = 'radio_button_checked',
    this.prayerTime,
    this.timePeriod,
    this.isSwitchMode = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final TasbihCollectionType type;
  final bool isDefault;
  final String color;
  final String icon;
  final String? prayerTime;
  final TimePeriod? timePeriod;
  final bool isSwitchMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TasbihCollection.fromMap(Map<String, dynamic> map) {
    return TasbihCollection(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      type: TasbihCollectionType.fromString(map['type'] as String),
      isDefault: (map['is_default'] as bool?) ?? false,
      color: (map['color'] as String?) ?? '#4CAF50',
      icon: (map['icon'] as String?) ?? 'radio_button_checked',
      prayerTime: map['prayer_time'] as String?,
      timePeriod: map['time_period'] != null
          ? TimePeriod.fromString(map['time_period'] as String)
          : null,
      isSwitchMode: (map['is_switch_mode'] as bool?) ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'type': type.value,
      'is_default': isDefault,
      'color': color,
      'icon': icon,
      'prayer_time': prayerTime,
      'time_period': timePeriod?.value,
      'is_switch_mode': isSwitchMode,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  TasbihCollection copyWith({
    String? name,
    String? description,
    TasbihCollectionType? type,
    bool? isDefault,
    String? color,
    String? icon,
    String? prayerTime,
    TimePeriod? timePeriod,
    bool? isSwitchMode,
    DateTime? updatedAt,
  }) {
    return TasbihCollection(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      prayerTime: prayerTime ?? this.prayerTime,
      timePeriod: timePeriod ?? this.timePeriod,
      isSwitchMode: isSwitchMode ?? this.isSwitchMode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  TasbihCollection toggleTimePeriod() {
    if (!isSwitchMode || timePeriod == null) return this;

    return copyWith(
      timePeriod: timePeriod!.toggle(),
      updatedAt: DateTime.now(),
    );
  }

  String get sectionTitle {
    switch (type) {
      case TasbihCollectionType.timeBased:
        return 'Dzikir Waktu';
      case TasbihCollectionType.prayerTimes:
        return 'Dzikir Setelah Sholat';
      case TasbihCollectionType.free:
        return 'Koleksi Kustom';
    }
  }

  String get sectionSubtitle {
    switch (type) {
      case TasbihCollectionType.timeBased:
        return isSwitchMode ? 'Dzikir pagi dan petang' : 'Dzikir waktu tertentu';
      case TasbihCollectionType.prayerTimes:
        return 'Koleksi dzikir setelah sholat fardhu';
      case TasbihCollectionType.free:
        return 'Koleksi dzikir personal';
    }
  }
}