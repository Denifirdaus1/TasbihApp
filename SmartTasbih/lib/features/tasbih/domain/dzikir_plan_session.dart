class DzikirTodo {
  const DzikirTodo({
    required this.goalId,
    required this.goalSessionId,
    required this.collectionId,
    required this.collectionName,
    required this.dhikrItemId,
    required this.dhikrText,
    required this.sessionName,
    required this.targetCount,
    required this.todayCount,
    required this.isCompleted,
    required this.orderIndex,
    required this.effectiveDaysOfWeek,
    this.sessionTime,
    this.dhikrTranslation,
    this.customDaysOfWeek,
    this.isActive = true,
  });

  final String goalId;
  final String goalSessionId;
  final String? collectionId;
  final String collectionName;
  final String? dhikrItemId;
  final String dhikrText;
  final String sessionName;
  final int targetCount;
  final int todayCount;
  final bool isCompleted;
  final int orderIndex;
  final List<int> effectiveDaysOfWeek;
  final String? sessionTime;
  final String? dhikrTranslation;
  final List<int>? customDaysOfWeek;
  final bool isActive;

  double get progress =>
      targetCount > 0 ? todayCount / targetCount : 0.0;

  factory DzikirTodo.fromMap(Map<String, dynamic> map) {
    return DzikirTodo(
      goalId: map['goal_id'] as String,
      goalSessionId: map['goal_session_id'] as String,
      collectionId: map['collection_id'] as String?,
      collectionName: map['collection_name'] as String? ?? '',
      dhikrItemId: map['dhikr_item_id'] as String?,
      dhikrText: map['dhikr_text'] as String? ?? map['session_name'] as String? ?? 'Dzikir',
      sessionName: map['session_name'] as String? ??
          map['dhikr_text'] as String? ??
          'Dzikir',
      targetCount: (map['target_count'] as num).toInt(),
      todayCount: (map['today_count'] as num?)?.toInt() ?? 0,
      isCompleted: map['is_completed'] as bool? ?? false,
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      effectiveDaysOfWeek:
          _parseDays(map['effective_days_of_week']) ?? const [1,2,3,4,5,6,7],
      sessionTime: map['session_time'] as String?,
      dhikrTranslation: map['dhikr_translation'] as String?,
      customDaysOfWeek: _parseDays(map['days_of_week']),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  static List<int>? _parseDays(dynamic value) {
    if (value == null) return null;
    if (value is List<dynamic>) {
      final list = value.map((e) => (e as num).toInt()).toList();
      return list.isEmpty ? null : list;
    }
    return null;
  }
}

class DzikirTodoInput {
  const DzikirTodoInput({
    required this.goalId,
    required this.collectionId,
    required this.dhikrItemId,
    required this.sessionTime,
    required this.targetCount,
    required this.daysOfWeek,
    this.name,
    this.orderIndex,
    this.isActive = true,
  });

  final String goalId;
  final String collectionId;
  final String dhikrItemId;
  final String sessionTime;
  final int targetCount;
  final int? orderIndex;
  final List<int> daysOfWeek;
  final String? name;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'collection_id': collectionId,
      'dhikr_item_id': dhikrItemId,
      'session_time': sessionTime,
      'target_count': targetCount,
      'days_of_week': daysOfWeek,
      'name': name,
      'is_active': isActive,
      if (orderIndex != null) 'order_index': orderIndex,
    };
  }
}
