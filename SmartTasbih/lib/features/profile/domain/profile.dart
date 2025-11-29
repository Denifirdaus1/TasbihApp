class Profile {
  const Profile({
    required this.id,
    required this.currentTreeLevel,
    required this.totalPoints,
    required this.dailyStreakCurrent,
    required this.dailyStreakLongest,
    this.username,
    this.avatarUrl,
    this.dailyStreakLastDate,
    this.updatedAt,
  });

  final String id;
  final String? username;
  final String? avatarUrl;
  final int currentTreeLevel;
  final int totalPoints;
  final int dailyStreakCurrent;
  final int dailyStreakLongest;
  final DateTime? dailyStreakLastDate;
  final DateTime? updatedAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      currentTreeLevel: (map['current_tree_level'] as num?)?.toInt() ?? 1,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
      dailyStreakCurrent: (map['daily_streak_current'] as num?)?.toInt() ?? 0,
      dailyStreakLongest: (map['daily_streak_longest'] as num?)?.toInt() ?? 0,
      dailyStreakLastDate: map['daily_streak_last_date'] != null
          ? DateTime.parse(map['daily_streak_last_date'] as String)
          : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'current_tree_level': currentTreeLevel,
      'total_points': totalPoints,
      'daily_streak_current': dailyStreakCurrent,
      'daily_streak_longest': dailyStreakLongest,
      'daily_streak_last_date': dailyStreakLastDate?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((_, value) => value == null);
  }

  Profile copyWith({
    String? username,
    String? avatarUrl,
    int? currentTreeLevel,
    int? totalPoints,
    int? dailyStreakCurrent,
    int? dailyStreakLongest,
    DateTime? dailyStreakLastDate,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentTreeLevel: currentTreeLevel ?? this.currentTreeLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      dailyStreakCurrent: dailyStreakCurrent ?? this.dailyStreakCurrent,
      dailyStreakLongest: dailyStreakLongest ?? this.dailyStreakLongest,
      dailyStreakLastDate: dailyStreakLastDate ?? this.dailyStreakLastDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get avatar URL with cache-busting parameter
  String get avatarUrlWithCache {
    if (avatarUrl == null) return '';

    // Parse existing URL and remove any existing cache parameters
    final uri = Uri.parse(avatarUrl!);
    final Map<String, String> params = Map.from(uri.queryParameters);

    // Add timestamp based on updatedAt or current time
    final timestamp = updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    params['t'] = timestamp.toString();

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters: params,
    ).toString();
  }
}
