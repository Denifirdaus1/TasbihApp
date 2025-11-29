class DzikirPlannerSummary {
  const DzikirPlannerSummary({
    required this.goalId,
    required this.userId,
    required this.goalName,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDailyTarget,
    required this.totalTodayCount,
    required this.allCompletedToday,
    required this.today,
    this.lastCompletedDate,
  });

  final String goalId;
  final String userId;
  final String goalName;
  final int currentStreak;
  final int longestStreak;
  final int totalDailyTarget;
  final int totalTodayCount;
  final bool allCompletedToday;
  final DateTime today;
  final DateTime? lastCompletedDate;

  double get progress =>
      totalDailyTarget > 0 ? totalTodayCount / totalDailyTarget : 0.0;

  int get remainingCount =>
      (totalDailyTarget - totalTodayCount).clamp(0, totalDailyTarget);

  factory DzikirPlannerSummary.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value as String);
    }

    final rawName = map['goal_name'] as String?;
    final safeName =
        rawName == null || rawName.trim().isEmpty ? 'Dzikir Harian' : rawName;

    return DzikirPlannerSummary(
      goalId: map['goal_id'] as String,
      userId: map['user_id'] as String,
      goalName: safeName,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      totalDailyTarget: (map['total_daily_target'] as num?)?.toInt() ?? 0,
      totalTodayCount: (map['total_today_count'] as num?)?.toInt() ?? 0,
      allCompletedToday: map['all_completed_today'] as bool? ?? false,
      today: DateTime.tryParse(map['today'] as String? ?? '') ?? DateTime.now(),
      lastCompletedDate: parseDate(map['last_completed_date']),
    );
  }
}
