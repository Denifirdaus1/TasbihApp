class Profile {
  const Profile({
    required this.id,
    required this.currentTreeLevel,
    required this.totalPoints,
    this.username,
    this.avatarUrl,
    this.updatedAt,
  });

  final String id;
  final String? username;
  final String? avatarUrl;
  final int currentTreeLevel;
  final int totalPoints;
  final DateTime? updatedAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      currentTreeLevel: (map['current_tree_level'] as num?)?.toInt() ?? 1,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
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
    }..removeWhere((_, value) => value == null);
  }

  Profile copyWith({
    String? username,
    String? avatarUrl,
    int? currentTreeLevel,
    int? totalPoints,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentTreeLevel: currentTreeLevel ?? this.currentTreeLevel,
      totalPoints: totalPoints ?? this.totalPoints,
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
