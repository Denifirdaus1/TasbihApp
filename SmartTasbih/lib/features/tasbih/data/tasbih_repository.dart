import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/dhikr_item.dart';
import '../domain/dzikir_plan.dart';
import '../domain/dzikir_plan_session.dart';
import '../domain/prayer_time.dart';
import '../domain/reminder_settings.dart';
import '../domain/tasbih_collection.dart';
import '../domain/tasbih_goal.dart';
import '../domain/tasbih_session.dart';
import '../domain/streak_update.dart';

class TasbihRepository {
  TasbihRepository(this._client);

  final SupabaseClient _client;

  // Collection Operations
  Future<List<TasbihCollection>> fetchCollections(String userId) async {
    final result = await _client
        .from('tasbih_collections')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<TasbihCollection>(TasbihCollection.fromMap)
        .toList();
  }

  Future<TasbihCollection> createCollection({
    required String userId,
    required String name,
    String? description,
    required TasbihCollectionType type,
    String? color,
    String? icon,
    String? prayerTime,
    TimePeriod? timePeriod,
    bool isSwitchMode = false,
    bool isDefault = false,
  }) async {
    final data = {
      'user_id': userId,
      'name': name,
      'description': description,
      'type': type.value,
      'color': color ?? '#4CAF50',
      'icon': icon ?? 'radio_button_checked',
      'prayer_time': prayerTime,
      'time_period': timePeriod?.value,
      'is_switch_mode': isSwitchMode,
      'is_default': isDefault,
    };

    final result = await _client
        .from('tasbih_collections')
        .insert(data)
        .select()
        .single();

    return TasbihCollection.fromMap(result);
  }

  Future<TasbihCollection> updateCollection(
    String collectionId, {
    String? name,
    String? description,
    String? color,
    String? icon,
    TimePeriod? timePeriod,
    bool? isSwitchMode,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (color != null) data['color'] = color;
    if (icon != null) data['icon'] = icon;
    if (timePeriod != null) data['time_period'] = timePeriod.value;
    if (isSwitchMode != null) data['is_switch_mode'] = isSwitchMode;

    final result = await _client
        .from('tasbih_collections')
        .update(data)
        .eq('id', collectionId)
        .select()
        .single();

    return TasbihCollection.fromMap(result);
  }

  Future<TasbihCollection> toggleTimePeriod(String collectionId) async {
    final result = await _client.rpc(
      'toggle_time_period',
      params: {'collection_id': collectionId},
    );

    return TasbihCollection.fromMap(result);
  }

  // Get collections by type for better organization
  Future<List<TasbihCollection>> fetchCollectionsByType(
    String userId,
    TasbihCollectionType type,
  ) async {
    final result = await _client
        .from('tasbih_collections')
        .select()
        .eq('user_id', userId)
        .eq('type', type.value)
        .order('created_at', ascending: false);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<TasbihCollection>(TasbihCollection.fromMap)
        .toList();
  }

  Future<TasbihCollection> fetchCollectionById({
    required String userId,
    required String collectionId,
  }) async {
    final result = await _client
        .from('tasbih_collections')
        .select()
        .eq('user_id', userId)
        .eq('id', collectionId)
        .maybeSingle();

    if (result == null) {
      throw Exception('Koleksi tidak ditemukan');
    }

    return TasbihCollection.fromMap(result);
  }

  Future<void> deleteCollection(String collectionId) async {
    await _client.from('tasbih_collections').delete().eq('id', collectionId);
  }

  // Dhikr Items Operations
  Future<List<DhikrItem>> fetchDhikrItems(String collectionId) async {
    final result = await _client
        .from('dhikr_items')
        .select()
        .eq('collection_id', collectionId)
        .order('order_index', ascending: true);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<DhikrItem>(DhikrItem.fromMap)
        .toList();
  }

  Future<DhikrItem?> fetchDhikrItemById(String dhikrItemId) async {
    final result = await _client
        .from('dhikr_items')
        .select()
        .eq('id', dhikrItemId)
        .maybeSingle();

    if (result == null) return null;
    return DhikrItem.fromMap(result);
  }

  Future<DhikrItem> createDhikrItem({
    required String collectionId,
    required String text,
    String? translation,
    int targetCount = 33,
    required int orderIndex,
  }) async {
    final data = {
      'collection_id': collectionId,
      'text': text,
      'translation': translation,
      'target_count': targetCount,
      'order_index': orderIndex,
    };

    final result = await _client
        .from('dhikr_items')
        .insert(data)
        .select()
        .single();

    return DhikrItem.fromMap(result);
  }

  Future<DhikrItem> updateDhikrItem(
    String itemId, {
    String? text,
    String? translation,
    int? targetCount,
    int? orderIndex,
  }) async {
    final data = <String, dynamic>{};
    if (text != null) data['text'] = text;
    if (translation != null) data['translation'] = translation;
    if (targetCount != null) data['target_count'] = targetCount;
    if (orderIndex != null) data['order_index'] = orderIndex;

    final result = await _client
        .from('dhikr_items')
        .update(data)
        .eq('id', itemId)
        .select()
        .single();

    return DhikrItem.fromMap(result);
  }

  Future<void> deleteDhikrItem(String itemId) async {
    await _client.from('dhikr_items').delete().eq('id', itemId);
  }

  Future<void> reorderDhikrItems(List<Map<String, dynamic>> items) async {
    await _client.from('dhikr_items').upsert(items);
  }

  // Session Operations
  Future<TasbihSession> getOrCreateSession({
    required String userId,
    required String collectionId,
    required String dhikrItemId,
    required int targetCount,
    DateTime? sessionDate,
    String? goalSessionId,
  }) async {
    final date = sessionDate ?? DateTime.now();
    final dateStr = date.toIso8601String().substring(0, 10); // YYYY-MM-DD

    // Try to get existing session
    var query = _client
        .from('tasbih_sessions')
        .select()
        .eq('user_id', userId)
        .eq('dhikr_item_id', dhikrItemId)
        .eq('session_date', dateStr);
    if (goalSessionId != null) {
      query = query.eq('goal_session_id', goalSessionId);
    } else {
      query = query.filter('goal_session_id', 'is', null);
    }

    final existingSession = await query.maybeSingle();

    if (existingSession != null) {
      return TasbihSession.fromMap(existingSession);
    }

    // Create new session
    final data = {
      'user_id': userId,
      'collection_id': collectionId,
      'dhikr_item_id': dhikrItemId,
      'count': 0,
      'target_count': targetCount,
      'session_date': dateStr,
      'goal_session_id': goalSessionId,
    };

    final result = await _client
        .from('tasbih_sessions')
        .insert(data)
        .select()
        .single();

    return TasbihSession.fromMap(result);
  }

  Future<TasbihSession> updateSessionCount(
    String sessionId,
    int count, {
    int? targetCount,
  }) async {
    final effectiveTarget = targetCount ?? 0;
    final completedAt = effectiveTarget > 0 && count >= effectiveTarget
        ? DateTime.now().toIso8601String()
        : null;

    final data = {'count': count, 'completed_at': completedAt};

    final result = await _client
        .from('tasbih_sessions')
        .update(data)
        .eq('id', sessionId)
        .select()
        .single();

    return TasbihSession.fromMap(result);
  }

  Future<TasbihSession> updateSessionTarget(
    String sessionId,
    int targetCount, {
    required int currentCount,
  }) async {
    final isCompleted = currentCount >= targetCount;
    final data = {
      'target_count': targetCount,
      'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
    };

    final result = await _client
        .from('tasbih_sessions')
        .update(data)
        .eq('id', sessionId)
        .select()
        .single();

    return TasbihSession.fromMap(result);
  }

  Future<List<TasbihSession>> fetchSessions({
    required String userId,
    String? collectionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('tasbih_sessions').select().eq('user_id', userId);

    if (collectionId != null) {
      query = query.eq('collection_id', collectionId);
    }

    if (startDate != null) {
      query = query.gte(
        'session_date',
        startDate.toIso8601String().substring(0, 10),
      );
    }

    if (endDate != null) {
      query = query.lte(
        'session_date',
        endDate.toIso8601String().substring(0, 10),
      );
    }

    final result = await query.order('session_date', ascending: false);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<TasbihSession>(TasbihSession.fromMap)
        .toList();
  }

  // Dzikir Planner helpers
  Future<DzikirPlannerSummary?> fetchPlannerSummary(String userId) async {
    final result = await _client
        .from('vw_dzikir_planner_summary')
        .select()
        .eq('user_id', userId)
        .order('total_daily_target', ascending: false)
        .order('goal_id', ascending: true)
        .limit(1)
        .maybeSingle();

    if (result == null) return null;
    return DzikirPlannerSummary.fromMap(result);
  }

  Future<List<DzikirTodo>> fetchDailyTodos(String userId) async {
    final result = await _client
        .from('vw_daily_dzikir_todos')
        .select()
        .eq('user_id', userId)
        .order('session_time', ascending: true)
        .order('order_index', ascending: true);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<DzikirTodo>(DzikirTodo.fromMap)
        .toList();
  }

  Future<TasbihGoal> ensureDailyPlannerGoal(String userId) async {
    final existing = await _client
        .from('tasbih_goals')
        .select()
        .eq('user_id', userId)
        .eq('goal_type', TasbihGoalType.daily.value)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return TasbihGoal.fromMap(existing);
    }

    final data = {
      'user_id': userId,
      'goal_type': TasbihGoalType.daily.value,
      'target_count': 0,
      'total_daily_target': 0,
      'start_date': DateTime.now().toIso8601String().substring(0, 10),
      'is_active': true,
      'days_of_week': const [1, 2, 3, 4, 5, 6, 7],
      'repeat_daily': true,
      'name': 'Dzikir Harian',
    };

    final result = await _client
        .from('tasbih_goals')
        .insert(data)
        .select()
        .single();

    return TasbihGoal.fromMap(result);
  }

  Future<void> createDzikirTodo(DzikirTodoInput input) async {
    final payload = input.toMap();
    payload['order_index'] =
        input.orderIndex ?? _orderIndexFromTime(input.sessionTime);

    await _client.from('tasbih_goal_sessions').insert(payload);
    await _syncGoalDailyTarget(input.goalId);
  }

  Future<void> updateDzikirTodo(
    String goalSessionId, {
    String? sessionTime,
    int? targetCount,
    List<int>? daysOfWeek,
    bool? isActive,
    String? name,
    String? collectionId,
    String? dhikrItemId,
  }) async {
    final data = <String, dynamic>{};
    if (sessionTime != null) {
      data['session_time'] = sessionTime;
      data['order_index'] = _orderIndexFromTime(sessionTime);
    }
    if (targetCount != null) data['target_count'] = targetCount;
    if (daysOfWeek != null) data['days_of_week'] = daysOfWeek;
    if (isActive != null) data['is_active'] = isActive;
    if (name != null) data['name'] = name;
    if (collectionId != null) data['collection_id'] = collectionId;
    if (dhikrItemId != null) data['dhikr_item_id'] = dhikrItemId;

    if (data.isEmpty) return;

    final updatedGoal = await _client
        .from('tasbih_goal_sessions')
        .update(data)
        .eq('id', goalSessionId)
        .select('goal_id')
        .maybeSingle();

    if (updatedGoal != null && (targetCount != null || isActive != null)) {
      final goalId = updatedGoal['goal_id'] as String;
      await _syncGoalDailyTarget(goalId);
    }
  }

  Future<void> updateGoalSessionTarget(
    String goalSessionId,
    int targetCount,
  ) async {
    final updated = await _client
        .from('tasbih_goal_sessions')
        .update({'target_count': targetCount})
        .eq('id', goalSessionId)
        .select('goal_id')
        .maybeSingle();

    if (updated != null) {
      await _syncGoalDailyTarget(updated['goal_id'] as String);
    }
  }

  Future<void> deleteDzikirTodo(String goalSessionId) async {
    await _client
        .from('tasbih_sessions')
        .update({'goal_session_id': null})
        .eq('goal_session_id', goalSessionId);

    final deleted = await _client
        .from('tasbih_goal_sessions')
        .delete()
        .eq('id', goalSessionId)
        .select('goal_id')
        .maybeSingle();

    if (deleted != null) {
      final goalId = deleted['goal_id'] as String;
      await _syncGoalDailyTarget(goalId);
    }
  }

  Future<void> markPlannerDayCompleted({
    required String goalId,
    required String userId,
  }) async {
    await _client.rpc(
      'mark_tasbih_goal_completed',
      params: {'p_goal_id': goalId, 'p_user_id': userId},
    );
  }

  Future<StreakUpdate?> updateDailyStreak({
    required String userId,
    DateTime? date,
  }) async {
    final params = {
      'p_user_id': userId,
      if (date != null) 'p_date': date.toIso8601String().substring(0, 10),
    };
    final result = await _client.rpc('update_daily_streak', params: params);
    if (result is Map<String, dynamic>) {
      return StreakUpdate.fromMap(result);
    }
    return null;
  }

  // Goal Operations
  Future<List<TasbihGoal>> fetchGoals(String userId) async {
    final result = await _client
        .from('tasbih_goals')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<TasbihGoal>(TasbihGoal.fromMap)
        .toList();
  }

  Future<TasbihGoal> createGoal({
    required String userId,
    required String collectionId,
    required TasbihGoalType goalType,
    required int targetCount,
    required DateTime startDate,
    DateTime? endDate,
    String? name,
  }) async {
    final normalizedName = _normalizePlanName(name);
    final data = {
      'user_id': userId,
      'collection_id': collectionId,
      'goal_type': goalType.value,
      'target_count': targetCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': true,
      if (normalizedName != null) 'name': normalizedName,
    };

    final result = await _client
        .from('tasbih_goals')
        .insert(data)
        .select()
        .single();

    return TasbihGoal.fromMap(result);
  }

  Future<TasbihGoal> updateGoal(
    String goalId, {
    TasbihGoalType? goalType,
    int? targetCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? name,
  }) async {
    final data = <String, dynamic>{};
    if (goalType != null) data['goal_type'] = goalType.value;
    if (targetCount != null) data['target_count'] = targetCount;
    if (startDate != null) data['start_date'] = startDate.toIso8601String();
    if (endDate != null) data['end_date'] = endDate.toIso8601String();
    if (isActive != null) data['is_active'] = isActive;
    if (name != null) {
      final normalizedName = _normalizePlanName(name);
      data['name'] = normalizedName;
    }

    final result = await _client
        .from('tasbih_goals')
        .update(data)
        .eq('id', goalId)
        .select()
        .single();

    return TasbihGoal.fromMap(result);
  }

  Future<void> deleteGoal(String goalId) async {
    await _client.from('tasbih_goals').delete().eq('id', goalId);
  }

  // Reminder Operations
  Future<List<ReminderSettings>> fetchReminders(String userId) async {
    final result = await _client
        .from('tasbih_reminders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .map<ReminderSettings>(ReminderSettings.fromMap)
        .toList();
  }

  Future<ReminderSettings?> fetchReminderByCollection(
    String userId,
    String collectionId,
  ) async {
    final result = await _client
        .from('tasbih_reminders')
        .select()
        .eq('user_id', userId)
        .eq('collection_id', collectionId)
        .maybeSingle();

    if (result == null) return null;
    return ReminderSettings.fromMap(result);
  }

  Future<ReminderSettings> createReminder(ReminderSettings reminder) async {
    final result = await _client
        .from('tasbih_reminders')
        .insert(reminder.toMap())
        .select()
        .single();

    return ReminderSettings.fromMap(result);
  }

  Future<ReminderSettings> updateReminder(
    String reminderId,
    Map<String, dynamic> updates,
  ) async {
    final result = await _client
        .from('tasbih_reminders')
        .update(updates)
        .eq('id', reminderId)
        .select()
        .single();

    return ReminderSettings.fromMap(result);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _client.from('tasbih_reminders').delete().eq('id', reminderId);
  }

  Future<ReminderSettings> saveReminderSettings({
    String? reminderId,
    required String userId,
    required String collectionId,
    required bool isEnabled,
    String? scheduledTime,
    String? customMessage,
    required List<int> daysOfWeek,
  }) async {
    final data = {
      'user_id': userId,
      'collection_id': collectionId,
      'is_enabled': isEnabled,
      'scheduled_time': scheduledTime,
      'custom_message': customMessage,
      'days_of_week': daysOfWeek,
    }..removeWhere((_, value) => value == null);

    final query = _client.from('tasbih_reminders');
    final result = reminderId == null
        ? await query.insert(data).select().single()
        : await query.update(data).eq('id', reminderId).select().single();

    return ReminderSettings.fromMap(result);
  }

  // Create Default Prayer Collections
  Future<List<TasbihCollection>> createDefaultPrayerCollections(
    String userId,
  ) async {
    final collections = <TasbihCollection>[];

    for (final collectionData in DefaultPrayerCollections.collections) {
      final collection = await createCollection(
        userId: userId,
        name: collectionData['name'] as String,
        description: collectionData['description'] as String,
        type: TasbihCollectionType.prayerTimes,
        color: collectionData['color'] as String,
        icon: collectionData['icon'] as String,
        prayerTime: collectionData['prayer_time'] as String,
        isDefault: true,
      );

      collections.add(collection);

      // Add default dhikr items to each collection
      for (
        var i = 0;
        i < DefaultPrayerCollections.defaultDhikrItems.length;
        i++
      ) {
        final item = DefaultPrayerCollections.defaultDhikrItems[i];
        await createDhikrItem(
          collectionId: collection.id,
          text: item['text'] as String,
          translation: item['translation'] as String?,
          targetCount: item['target_count'] as int,
          orderIndex: i,
        );
      }
    }

    return collections;
  }

  // Create Default Time-Based Collection (pagi/petang switch)
  Future<TasbihCollection?> createTimeBasedCollection(String userId) async {
    // Check if already exists
    final existing = await _client
        .from('tasbih_collections')
        .select()
        .eq('user_id', userId)
        .eq('type', 'time_based')
        .eq('is_switch_mode', true)
        .maybeSingle();

    if (existing != null) {
      return TasbihCollection.fromMap(existing);
    }

    final collection = await createCollection(
      userId: userId,
      name: 'Dzikir Pagi & Petang',
      description: 'Dzikir yang bisa dibaca pagi dan petang hari',
      type: TasbihCollectionType.timeBased,
      color: '#9C27B0',
      icon: 'wb_twilight',
      timePeriod: TimePeriod.pagi,
      isSwitchMode: true,
      isDefault: true,
    );

    // Add default time-based dhikr items
    final defaultTimeDhikrItems =
        DefaultPrayerCollections.defaultTimeDhikrItems;
    for (var i = 0; i < defaultTimeDhikrItems.length; i++) {
      final item = defaultTimeDhikrItems[i];
      await createDhikrItem(
        collectionId: collection.id,
        text: item['text'] as String,
        translation: item['translation'] as String?,
        targetCount: item['target_count'] as int,
        orderIndex: i,
      );
    }

    return collection;
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('tasbih_sessions')
        .select('count, target_count, session_date')
        .eq('user_id', userId);

    if (startDate != null) {
      query = query.gte(
        'session_date',
        startDate.toIso8601String().substring(0, 10),
      );
    }

    if (endDate != null) {
      query = query.lte(
        'session_date',
        endDate.toIso8601String().substring(0, 10),
      );
    }

    final result = await query;

    int totalCount = 0;
    int completedCount = 0;
    final Map<String, int> dailyStats = {};

    for (final session in result) {
      final count = (session['count'] as num?)?.toInt() ?? 0;
      final targetCount = (session['target_count'] as num?)?.toInt() ?? 0;
      final date = session['session_date'] as String;

      totalCount += count;
      if (count >= targetCount) completedCount++;

      dailyStats[date] = (dailyStats[date] ?? 0) + count;
    }

    return {
      'totalCount': totalCount,
      'completedCount': completedCount,
      'dailyStats': dailyStats,
    };
  }

  String? _normalizePlanName(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _syncGoalDailyTarget(String goalId) async {
    final result = await _client
        .from('tasbih_goal_sessions')
        .select('target_count')
        .eq('goal_id', goalId)
        .eq('is_active', true);

    final total = (result as List).fold<int>(
      0,
      (sum, item) => sum + ((item['target_count'] as num?)?.toInt() ?? 0),
    );

    await _client
        .from('tasbih_goals')
        .update({'total_daily_target': total})
        .eq('id', goalId);
  }

  int _orderIndexFromTime(String sessionTime) {
    final parts = sessionTime.split(':');
    if (parts.length < 2) {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
}
