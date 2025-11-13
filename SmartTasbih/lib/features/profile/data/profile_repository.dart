import 'dart:io';
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

  Future<void> updateUsername(String userId, String username) {
    return _client.from('profiles').update({
      'username': username,
    }).eq('id', userId);
  }

  Future<void> updateAvatarUrl(String userId, String avatarUrl) {
    return _client.from('profiles').update({
      'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  Future<String> uploadProfileImage(String userId, String filePath) async {
    final file = File(filePath);
    final fileExt = filePath.split('.').last;
    final fileName = '$userId/profile.$fileExt';

    await _client.storage.from('profiles').upload(
      fileName,
      file,
      fileOptions: FileOptions(
        upsert: true,
      ),
    );

    // Get public URL with auto-compression
    final publicUrl = _client.storage.from('profiles').getPublicUrl(fileName);

    // Add image transformation parameters for auto-compression and optimization
    // Add timestamp for cache-busting to force refresh
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?width=400&height=400&quality=80&format=webp&t=$timestamp';
  }
}
