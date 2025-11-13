class PrayerCircle {
  const PrayerCircle({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;

  factory PrayerCircle.fromMap(Map<String, dynamic> map) {
    return PrayerCircle(
      id: map['id'] as int,
      name: map['circle_name'] as String,
      inviteCode: map['invite_code'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CircleGoal {
  const CircleGoal({
    required this.id,
    required this.circleId,
    required this.targetCount,
    required this.currentCount,
    required this.isActive,
    this.zikirName,
    this.createdBy,
  });

  final int id;
  final int circleId;
  final int targetCount;
  final int currentCount;
  final bool isActive;
  final String? zikirName;
  final String? createdBy;

  double get progress =>
      targetCount == 0 ? 0 : currentCount / targetCount.toDouble();

  factory CircleGoal.fromMap(Map<String, dynamic> map) {
    return CircleGoal(
      id: map['id'] as int,
      circleId: map['circle_id'] as int,
      targetCount: (map['target_count'] as num).toInt(),
      currentCount: (map['current_count'] as num).toInt(),
      isActive: map['is_active'] as bool? ?? true,
      zikirName: map['zikir_master']?['name'] as String?,
      createdBy: map['created_by'] as String?,
    );
  }
}
