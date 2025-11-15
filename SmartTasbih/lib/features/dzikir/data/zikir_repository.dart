import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/zikir_models.dart';

class ZikirRepository {
  ZikirRepository(this._client);

  final SupabaseClient _client;

  Future<List<UserZikirCollection>> fetchCollections(String userId) async {
    final data = await _client
        .from('user_zikir_collections')
        .select('''
          id,
          zikir_id,
          target_count,
          custom_name,
          zikir_master (
            id,
            name,
            arabic_text,
            translation,
            fadilah_content
          )
        ''')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(data as List)
        .map(UserZikirCollection.fromMap)
        .toList();
  }

  Future<void> upsertCustomZikir({
    required String userId,
    required String name,
    int targetCount = 100,
  }) {
    return _client.from('user_zikir_collections').insert({
      'user_id': userId,
      'custom_name': name,
      'target_count': targetCount,
    });
  }

  Future<void> incrementGoalCount({
    required String userId,
    required int amount,
  }) async {
    await _client.rpc(
      'increment_goal_count',
      params: {
        'user_id_input': userId,
        'amount_to_add': amount,
      },
    );
  }
}
