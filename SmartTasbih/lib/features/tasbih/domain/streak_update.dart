class StreakUpdate {
  const StreakUpdate({
    required this.event,
    required this.currentStreak,
    required this.longestStreak,
  });

  final String event;
  final int currentStreak;
  final int longestStreak;

  factory StreakUpdate.fromMap(Map<String, dynamic> map) {
    return StreakUpdate(
      event: map['event'] as String? ?? 'no_change',
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }

  bool get shouldCelebrate =>
      event == 'started' || event == 'continued' || event == 'frozen_saved';

  bool get isFrozenSaved => event == 'frozen_saved';
}

