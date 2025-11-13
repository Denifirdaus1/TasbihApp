import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/prayer_circle_models.dart';

class PrayerCircleRepository {
  PrayerCircleRepository(this._client);

  final SupabaseClient _client;
  final _random = Random();

  Future<List<PrayerCircle>> fetchCircles(String userId) async {
    final rows = await _client
        .from('prayer_circles')
        .select('''
          id,
          circle_name,
          invite_code,
          created_at,
          created_by,
          circle_members!inner (user_id)
        ''')
        .eq('circle_members.user_id', userId);
    final mappedRows =
        (rows as List).cast<Map<String, dynamic>>();
    return mappedRows
        .map((row) => PrayerCircle.fromMap(row))
        .toList();
  }

  Stream<List<CircleGoal>> goalsStream(int circleId) {
    return _client
        .from('circle_goals')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .order('created_at')
        .map(
          (rows) => (rows as List)
              .cast<Map<String, dynamic>>()
              .map(CircleGoal.fromMap)
              .toList(),
        );
  }

  Future<PrayerCircle> createCircle({
    required String name,
    required String userId,
  }) async {
    final inviteCode = _generateCode();
    final inserted = await _client
        .from('prayer_circles')
        .insert({
          'circle_name': name,
          'invite_code': inviteCode,
          'created_by': userId,
        })
        .select()
        .single();
    await _client.from('circle_members').insert({
      'circle_id': inserted['id'],
      'user_id': userId,
    });
    return PrayerCircle.fromMap(inserted);
  }

  Future<void> joinByCode({
    required String inviteCode,
    required String userId,
  }) async {
    final circle = await _client
        .from('prayer_circles')
        .select('id')
        .eq('invite_code', inviteCode)
        .maybeSingle();
    if (circle == null) throw Exception('Kode tidak ditemukan.');

    await _client.from('circle_members').upsert({
      'circle_id': circle['id'],
      'user_id': userId,
    });
  }

  Future<void> createGoal({
    required int circleId,
    required String userId,
    required int target,
    required int zikirId,
  }) {
    return _client.from('circle_goals').insert({
      'circle_id': circleId,
      'target_count': target,
      'zikir_id': zikirId,
      'created_by': userId,
    });
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}
