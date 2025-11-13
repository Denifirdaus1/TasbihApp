class Profile {
  const Profile({
    required this.id,
    required this.currentTreeLevel,
    required this.totalPoints,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String? username;
  final String? avatarUrl;
  final int currentTreeLevel;
  final int totalPoints;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      currentTreeLevel: (map['current_tree_level'] as num?)?.toInt() ?? 1,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'current_tree_level': currentTreeLevel,
      'total_points': totalPoints,
    }..removeWhere((_, value) => value == null);
  }

  Profile copyWith({
    String? username,
    String? avatarUrl,
    int? currentTreeLevel,
    int? totalPoints,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentTreeLevel: currentTreeLevel ?? this.currentTreeLevel,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}
