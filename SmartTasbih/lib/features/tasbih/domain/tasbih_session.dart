class TasbihSession {
  const TasbihSession({
    required this.id,
    required this.userId,
    required this.collectionId,
    required this.dhikrItemId,
    required this.count,
    required this.targetCount,
    required this.sessionDate,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String collectionId;
  final String dhikrItemId;
  final int count;
  final int targetCount;
  final DateTime sessionDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => count >= targetCount;
  double get progress => targetCount > 0 ? count / targetCount : 0.0;

  factory TasbihSession.fromMap(Map<String, dynamic> map) {
    return TasbihSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      collectionId: map['collection_id'] as String,
      dhikrItemId: map['dhikr_item_id'] as String,
      count: (map['count'] as num?)?.toInt() ?? 0,
      targetCount: (map['target_count'] as num?)?.toInt() ?? 33,
      sessionDate: DateTime.parse(map['session_date'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'collection_id': collectionId,
      'dhikr_item_id': dhikrItemId,
      'count': count,
      'target_count': targetCount,
      'session_date': sessionDate.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  TasbihSession copyWith({
    int? count,
    int? targetCount,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return TasbihSession(
      id: id,
      userId: userId,
      collectionId: collectionId,
      dhikrItemId: dhikrItemId,
      count: count ?? this.count,
      targetCount: targetCount ?? this.targetCount,
      sessionDate: sessionDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}