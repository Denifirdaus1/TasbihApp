import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../data/tasbih_repository.dart';
import '../domain/dhikr_item.dart';
import '../domain/dzikir_plan.dart';
import '../domain/dzikir_plan_session.dart';
import '../domain/tasbih_collection.dart';
import '../domain/tasbih_goal.dart';
import '../domain/tasbih_session.dart';

// Repository Provider
final tasbihRepositoryProvider = Provider<TasbihRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TasbihRepository(client);
});

// Collection Providers
final collectionsProvider = FutureProvider<List<TasbihCollection>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final repository = ref.watch(tasbihRepositoryProvider);
  return repository.fetchCollections(userId);
});

final collectionDetailProvider =
    FutureProvider.family<TasbihCollection, String>((ref, collectionId) async {
      final repository = ref.watch(tasbihRepositoryProvider);
      final userId = ref.watch(currentUserProvider)?.id;

      if (userId == null) throw Exception('User not authenticated');

      final collections = await repository.fetchCollections(userId);
      final collection = collections.firstWhere((c) => c.id == collectionId);
      return collection;
    });

// Dhikr Items Providers
final dhikrItemsProvider = FutureProvider.family<List<DhikrItem>, String>((
  ref,
  collectionId,
) async {
  final repository = ref.watch(tasbihRepositoryProvider);
  return repository.fetchDhikrItems(collectionId);
});

// Session Providers
final tasbihSessionProvider =
    FutureProvider.family<TasbihSession, SessionParams>((ref, params) async {
      final repository = ref.watch(tasbihRepositoryProvider);
      return repository.getOrCreateSession(
        userId: params.userId,
        collectionId: params.collectionId,
        dhikrItemId: params.dhikrItemId,
        targetCount: params.targetCount,
        sessionDate: params.sessionDate,
        goalSessionId: params.goalSessionId,
      );
    });

// Counter controller provider for session management
final counterControllerProvider =
    FutureProvider.family<TasbihSession, SessionParams>((ref, params) async {
      final repository = ref.watch(tasbihRepositoryProvider);
      return repository.getOrCreateSession(
        userId: params.userId,
        collectionId: params.collectionId,
        dhikrItemId: params.dhikrItemId,
        targetCount: params.targetCount,
        sessionDate: params.sessionDate,
        goalSessionId: params.goalSessionId,
      );
    });

class SessionParams {
  const SessionParams({
    required this.userId,
    required this.collectionId,
    required this.dhikrItemId,
    required this.targetCount,
    this.sessionDate,
    this.planGoalId,
    this.goalSessionId,
  });

  final String userId;
  final String collectionId;
  final String dhikrItemId;
  final int targetCount;
  final DateTime? sessionDate;
  final String? planGoalId;
  final String? goalSessionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          collectionId == other.collectionId &&
          dhikrItemId == other.dhikrItemId &&
          targetCount == other.targetCount &&
          sessionDate == other.sessionDate &&
          planGoalId == other.planGoalId &&
          goalSessionId == other.goalSessionId;

  @override
  int get hashCode =>
      userId.hashCode ^
      collectionId.hashCode ^
      dhikrItemId.hashCode ^
      targetCount.hashCode ^
      sessionDate.hashCode ^
      (planGoalId?.hashCode ?? 0) ^
      (goalSessionId?.hashCode ?? 0);
}

// Session History Provider
final sessionsProvider =
    FutureProvider.family<List<TasbihSession>, SessionsParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(tasbihRepositoryProvider);
      return repository.fetchSessions(
        userId: params.userId,
        collectionId: params.collectionId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

class SessionsParams {
  const SessionsParams({
    required this.userId,
    this.collectionId,
    this.startDate,
    this.endDate,
  });

  final String userId;
  final String? collectionId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionsParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          collectionId == other.collectionId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      userId.hashCode ^
      collectionId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

final dzikirPlannerSummaryProvider =
    FutureProvider<DzikirPlannerSummary?>((ref) async {
      final userId = ref.watch(currentUserProvider)?.id;
      if (userId == null) return null;

      final repository = ref.watch(tasbihRepositoryProvider);
      return repository.fetchPlannerSummary(userId);
    });

final dailyDzikirTodosProvider =
    FutureProvider<List<DzikirTodo>>((ref) async {
      final userId = ref.watch(currentUserProvider)?.id;
      if (userId == null) return [];

      final repository = ref.watch(tasbihRepositoryProvider);
      return repository.fetchDailyTodos(userId);
    });

final createDzikirTodoProvider =
    NotifierProvider<CreateDzikirTodoNotifier, AsyncValue<void>>(
      CreateDzikirTodoNotifier.new,
    );
final updateDzikirTodoProvider =
    NotifierProvider<UpdateDzikirTodoNotifier, AsyncValue<void>>(
      UpdateDzikirTodoNotifier.new,
    );
final deleteDzikirTodoProvider =
    NotifierProvider<DeleteDzikirTodoNotifier, AsyncValue<void>>(
      DeleteDzikirTodoNotifier.new,
    );

// Goals Provider
final goalsProvider = FutureProvider<List<TasbihGoal>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final repository = ref.watch(tasbihRepositoryProvider);
  return repository.fetchGoals(userId);
});

// Statistics Provider
final statisticsProvider =
    FutureProvider.family<Map<String, dynamic>, StatisticsParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(tasbihRepositoryProvider);
      return repository.getStatistics(
        params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

class StatisticsParams {
  const StatisticsParams({required this.userId, this.startDate, this.endDate});

  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => userId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// Simple providers for operations
final createCollectionProvider =
    NotifierProvider<CreateCollectionNotifier, AsyncValue<void>>(
      CreateCollectionNotifier.new,
    );
final createDhikrItemProvider =
    NotifierProvider<CreateDhikrItemNotifier, AsyncValue<void>>(
      CreateDhikrItemNotifier.new,
    );
final updateSessionProvider =
    NotifierProvider<UpdateSessionNotifier, AsyncValue<TasbihSession>>(
      UpdateSessionNotifier.new,
    );
final deleteCollectionProvider =
    NotifierProvider<DeleteCollectionNotifier, AsyncValue<void>>(
      DeleteCollectionNotifier.new,
    );
final deleteDhikrItemProvider =
    NotifierProvider<DeleteDhikrItemNotifier, AsyncValue<void>>(
      DeleteDhikrItemNotifier.new,
    );
final updateCollectionProvider =
    NotifierProvider<UpdateCollectionNotifier, AsyncValue<void>>(
      UpdateCollectionNotifier.new,
    );
final updateDhikrItemProvider =
    NotifierProvider<UpdateDhikrItemNotifier, AsyncValue<void>>(
      UpdateDhikrItemNotifier.new,
    );

// Helper functions for operations
Future<void> createCollectionAction(
  WidgetRef ref, {
  required String name,
  String? description,
  required TasbihCollectionType type,
  String? color,
  String? icon,
  String? prayerTime,
}) async {
  final notifier = ref.read(createCollectionProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final repository = ref.read(tasbihRepositoryProvider);
    await repository.createCollection(
      userId: userId,
      name: name,
      description: description,
      type: type,
      color: color,
      icon: icon,
      prayerTime: prayerTime,
    );

    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(collectionsProvider);
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
  }
}

Future<void> createDhikrItemAction(
  WidgetRef ref, {
  required String collectionId,
  required String text,
  String? translation,
  int targetCount = 33,
}) async {
  final notifier = ref.read(createDhikrItemProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    final items = await repository.fetchDhikrItems(collectionId);
    final orderIndex = items.length;

    await repository.createDhikrItem(
      collectionId: collectionId,
      text: text,
      translation: translation,
      targetCount: targetCount,
      orderIndex: orderIndex,
    );

    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(dhikrItemsProvider(collectionId));
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
  }
}

Future<TasbihSession> updateSessionAction(
  WidgetRef ref, {
  required SessionParams params,
  required int count,
}) async {
  final notifier = ref.read(updateSessionProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    final currentSession = await repository.getOrCreateSession(
      userId: params.userId,
      collectionId: params.collectionId,
      dhikrItemId: params.dhikrItemId,
      targetCount: params.targetCount,
      sessionDate: params.sessionDate,
      goalSessionId: params.goalSessionId,
    );

    final updatedSession = await repository.updateSessionCount(
      currentSession.id,
      count,
      targetCount: params.targetCount,
    );
    notifier.updateState(AsyncValue.data(updatedSession));
    return updatedSession;
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
    rethrow;
  }
}

Future<void> deleteCollectionAction(
  WidgetRef ref, {
  required String collectionId,
}) async {
  final notifier = ref.read(deleteCollectionProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    await repository.deleteCollection(collectionId);
    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(collectionsProvider);
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
  }
}

Future<void> deleteDhikrItemAction(
  WidgetRef ref, {
  required String itemId,
}) async {
  final notifier = ref.read(deleteDhikrItemProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    await repository.deleteDhikrItem(itemId);
    notifier.updateState(const AsyncValue.data(null));
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
  }
}

Future<TasbihCollection> updateCollectionAction(
  WidgetRef ref, {
  required String collectionId,
  String? name,
  String? description,
  String? color,
  String? icon,
}) async {
  final notifier = ref.read(updateCollectionProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    final updated = await repository.updateCollection(
      collectionId,
      name: name,
      description: description,
      color: color,
      icon: icon,
    );
    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(collectionsProvider);
    ref.invalidate(collectionDetailProvider(collectionId));
    return updated;
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
    rethrow;
  }
}

Future<DhikrItem> updateDhikrItemAction(
  WidgetRef ref, {
  required String collectionId,
  required String itemId,
  String? text,
  String? translation,
  int? targetCount,
}) async {
  final notifier = ref.read(updateDhikrItemProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    final updated = await repository.updateDhikrItem(
      itemId,
      text: text,
      translation: translation,
      targetCount: targetCount,
    );
    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(dhikrItemsProvider(collectionId));
    return updated;
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
    rethrow;
  }
}

// Notifier classes for Riverpod 3.0 compatibility
class CreateCollectionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class CreateDhikrItemNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class UpdateSessionNotifier extends Notifier<AsyncValue<TasbihSession>> {
  @override
  AsyncValue<TasbihSession> build() => const AsyncValue.loading();

  void updateState(AsyncValue<TasbihSession> value) => state = value;
}

class DeleteCollectionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class DeleteDhikrItemNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class UpdateCollectionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class UpdateDhikrItemNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class CreateDzikirTodoNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class UpdateDzikirTodoNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

class DeleteDzikirTodoNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void updateState(AsyncValue<void> value) => state = value;
}

// Create Default Collections
Future<void> createDefaultCollectionsAction(WidgetRef ref) async {
  try {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final repository = ref.read(tasbihRepositoryProvider);
    await repository.createDefaultPrayerCollections(userId);

    ref.invalidate(collectionsProvider);
  } catch (e) {
    rethrow;
  }
}

Future<TasbihGoal> ensureDailyPlannerGoalAction(WidgetRef ref) async {
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.read(tasbihRepositoryProvider);
  final goal = await repository.ensureDailyPlannerGoal(userId);
  ref.invalidate(dzikirPlannerSummaryProvider);
  return goal;
}

Future<void> createDzikirTodoAction(
  WidgetRef ref, {
  required String collectionId,
  required String dhikrItemId,
  required String sessionTime,
  required int targetCount,
  required List<int> daysOfWeek,
  String? name,
}) async {
  final notifier = ref.read(createDzikirTodoProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final goal = await ensureDailyPlannerGoalAction(ref);
    final input = DzikirTodoInput(
      goalId: goal.id,
      collectionId: collectionId,
      dhikrItemId: dhikrItemId,
      sessionTime: sessionTime,
      targetCount: targetCount,
      daysOfWeek: daysOfWeek,
      name: name,
    );

    await ref.read(tasbihRepositoryProvider).createDzikirTodo(input);
    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(dailyDzikirTodosProvider);
    ref.invalidate(dzikirPlannerSummaryProvider);
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
    rethrow;
  }
}

Future<void> updateDzikirTodoAction(
  WidgetRef ref, {
  required String goalSessionId,
  String? sessionTime,
  int? targetCount,
  List<int>? daysOfWeek,
  bool? isActive,
  String? name,
  String? collectionId,
  String? dhikrItemId,
}) async {
  final notifier = ref.read(updateDzikirTodoProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    await repository.updateDzikirTodo(
      goalSessionId,
      sessionTime: sessionTime,
      targetCount: targetCount,
      daysOfWeek: daysOfWeek,
      isActive: isActive,
      name: name,
      collectionId: collectionId,
      dhikrItemId: dhikrItemId,
    );

    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(dailyDzikirTodosProvider);
    ref.invalidate(dzikirPlannerSummaryProvider);
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
    rethrow;
  }
}

Future<void> deleteDzikirTodoAction(
  WidgetRef ref, {
  required String goalSessionId,
}) async {
  final notifier = ref.read(deleteDzikirTodoProvider.notifier);
  notifier.updateState(const AsyncValue.loading());
  try {
    final repository = ref.read(tasbihRepositoryProvider);
    await repository.deleteDzikirTodo(goalSessionId);
    notifier.updateState(const AsyncValue.data(null));
    ref.invalidate(dailyDzikirTodosProvider);
    ref.invalidate(dzikirPlannerSummaryProvider);
  } catch (e, stackTrace) {
    notifier.updateState(AsyncValue.error(e, stackTrace));
    rethrow;
  }
}

// Create Time-Based Collection
Future<void> createTimeBasedCollectionAction(WidgetRef ref) async {
  try {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final repository = ref.read(tasbihRepositoryProvider);
    await repository.createTimeBasedCollection(userId);

    ref.invalidate(collectionsProvider);
  } catch (e) {
    rethrow;
  }
}
