import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';
import '../domain/user_badge.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> fetchProfile(String userId) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (result == null) {
      throw Exception('Profil belum tersedia untuk user: $userId');
    }

    return Profile.fromMap(result);
  }

  Future<List<UserBadge>> fetchBadges(String userId) async {
    final rows = await _client
        .from('user_badges')
        .select()
        .eq('user_id', userId)
        .order('achieved_at');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map<UserBadge>(UserBadge.fromMap)
        .toList();
  }

  Future<void> updateTreeLevel(String userId, int level) {
    return _client.from('profiles').update({
      'current_tree_level': level,
    }).eq('id', userId);
  }
}
