import 'tasbih_collection.dart';

class TasbihGoal {
  const TasbihGoal({
    required this.id,
    required this.userId,
    required this.collectionId,
    required this.goalType,
    required this.targetCount,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String collectionId;
  final TasbihGoalType goalType;
  final int targetCount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TasbihGoal.fromMap(Map<String, dynamic> map) {
    return TasbihGoal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      collectionId: map['collection_id'] as String,
      goalType: TasbihGoalType.fromString(map['goal_type'] as String),
      targetCount: (map['target_count'] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'collection_id': collectionId,
      'goal_type': goalType.value,
      'target_count': targetCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  TasbihGoal copyWith({
    TasbihGoalType? goalType,
    int? targetCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return TasbihGoal(
      id: id,
      userId: userId,
      collectionId: collectionId,
      goalType: goalType ?? this.goalType,
      targetCount: targetCount ?? this.targetCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}