class AchievementOverview {
  const AchievementOverview({
    required this.totalClicks,
    required this.totalCollections,
    required this.completedSessions,
    required this.dailyStats,
  });

  final int totalClicks;
  final int totalCollections;
  final int completedSessions;
  final Map<String, int> dailyStats;

  double get completionRate {
    if (totalCollections == 0) {
      return 0;
    }
    return (completedSessions / totalCollections).clamp(0, 1).toDouble();
  }

  double get averageDailyCount {
    if (dailyStats.isEmpty) {
      return 0;
    }
    return totalClicks / dailyStats.length;
  }

  List<MapEntry<String, int>> get lastSevenDaysTrend {
    if (dailyStats.isEmpty) {
      return const <MapEntry<String, int>>[];
    }

    final sorted = dailyStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sorted.length <= 7) {
      return sorted;
    }

    return sorted.sublist(sorted.length - 7);
  }
}
