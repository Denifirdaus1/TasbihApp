class UserBadge {
  const UserBadge({
    required this.badgeName,
    required this.achievedAt,
  });

  final String badgeName;
  final DateTime achievedAt;

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      badgeName: map['badge_name'] as String,
      achievedAt: DateTime.parse(map['achieved_at'] as String),
    );
  }
}
