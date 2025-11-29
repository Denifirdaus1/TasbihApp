import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import '../data/tasbih_repository.dart';
import 'counter_baseline_store.dart';
import 'tasbih_providers.dart';
import '../domain/streak_update.dart';

class CounterState {
  final String sessionId;
  final int displayCount;
  final int savedCount;
  final int pendingCount;
  final int targetCount;
  final int baselineCount;
  final bool isCompleted;
  final bool isSyncing;
  final StreakUpdate? streakUpdate;

  const CounterState({
    required this.sessionId,
    required this.displayCount,
    required this.savedCount,
    required this.pendingCount,
    required this.targetCount,
    this.baselineCount = 0,
    this.isCompleted = false,
    this.isSyncing = false,
    this.streakUpdate,
  });

  double get progress => targetCount > 0 ? displayCount / targetCount : 0.0;
  int get actualCount => baselineCount + displayCount;

  CounterState copyWith({
    String? sessionId,
    int? displayCount,
    int? savedCount,
    int? pendingCount,
    int? targetCount,
    int? baselineCount,
    bool? isCompleted,
    bool? isSyncing,
    StreakUpdate? streakUpdate,
  }) {
    return CounterState(
      sessionId: sessionId ?? this.sessionId,
      displayCount: displayCount ?? this.displayCount,
      savedCount: savedCount ?? this.savedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      targetCount: targetCount ?? this.targetCount,
      baselineCount: baselineCount ?? this.baselineCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isSyncing: isSyncing ?? this.isSyncing,
      streakUpdate: streakUpdate ?? this.streakUpdate,
    );
  }
}

class TasbihCounterController extends StateNotifier<CounterState> {
  TasbihCounterController(
    this._repository,
    this._sessionParams,
    CounterState initialState,
  ) : super(initialState);

  final TasbihRepository _repository;
  final SessionParams _sessionParams;
  Timer? _autoSaveTimer;
  bool _disposed = false;
  bool _isSyncingPlan = false;

  static const int _batchSize = 30;
  static const Duration _autoSaveDelay = Duration(seconds: 3);

  void increment() {
    if (state.isCompleted) return;

    final newDisplayCount = state.displayCount + 1;
    final newPendingCount = state.pendingCount + 1;
    final isCompleted = newDisplayCount >= state.targetCount;

    // Update UI instantly (REAL-TIME!)
    state = state.copyWith(
      displayCount: newDisplayCount,
      pendingCount: newPendingCount,
      isCompleted: isCompleted,
    );

    // Cancel previous timer
    _autoSaveTimer?.cancel();

    // Check if we should sync now (every 30 clicks)
    if (newPendingCount >= _batchSize || isCompleted) {
      _syncToDatabase();
    } else {
      // Set timer to auto-save after 3 seconds of inactivity
      _autoSaveTimer = Timer(_autoSaveDelay, () {
        _syncToDatabase();
      });
    }
  }

  Future<void> setCount(int count) async {
    if (count < 0) return;

    final isCompleted = count >= state.targetCount;
    final targetActualCount = state.baselineCount + count;

    state = state.copyWith(
      displayCount: count,
      pendingCount: targetActualCount - state.savedCount,
      isCompleted: isCompleted,
      isSyncing: true,
    );

    await _syncToDatabase(forceCount: count);
  }

  Future<void> updateTarget(int targetCount) async {
    if (targetCount <= 0) return;

    final isCompleted = state.displayCount >= targetCount;

    state = state.copyWith(
      targetCount: targetCount,
      isCompleted: isCompleted,
      isSyncing: true,
    );

    try {
      final session = await _repository.getOrCreateSession(
        userId: _sessionParams.userId,
        collectionId: _sessionParams.collectionId,
        dhikrItemId: _sessionParams.dhikrItemId,
        targetCount: targetCount,
        sessionDate: _sessionParams.sessionDate,
        goalSessionId: _sessionParams.goalSessionId,
      );

      await _repository.updateSessionTarget(
        session.id,
        targetCount,
        currentCount: state.displayCount,
      );

      if (_sessionParams.goalSessionId != null) {
        await _repository.updateGoalSessionTarget(
          _sessionParams.goalSessionId!,
          targetCount,
        );
      }

      if (!_disposed) {
        state = state.copyWith(isSyncing: false);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }

  Future<void> reset() async {
    if (state.pendingCount != 0) {
      await _syncToDatabase();
    }

    if (state.sessionId.isEmpty) {
      return;
    }

    final baseline = state.savedCount;
    await CounterBaselineStore.saveBaseline(state.sessionId, baseline);

    if (_disposed) return;

    state = state.copyWith(
      baselineCount: baseline,
      displayCount: 0,
      pendingCount: 0,
      isCompleted: false,
      isSyncing: false,
    );
  }

  Future<void> _syncToDatabase({int? forceCount}) async {
    if (_disposed) return;

    if (state.pendingCount == 0 && forceCount == null) return;

    try {
      state = state.copyWith(isSyncing: true);

      final session = await _repository.getOrCreateSession(
        userId: _sessionParams.userId,
        collectionId: _sessionParams.collectionId,
        dhikrItemId: _sessionParams.dhikrItemId,
        targetCount: state.targetCount,
        sessionDate: _sessionParams.sessionDate,
        goalSessionId: _sessionParams.goalSessionId,
      );

      var baseline = state.baselineCount;
      if (session.id != state.sessionId) {
        final storedBaseline = await CounterBaselineStore.readBaseline(
          session.id,
        );
        baseline = storedBaseline.clamp(0, session.count);
      }

      final newDisplayCount = forceCount ?? state.displayCount;
      final actualCount = newDisplayCount + baseline;
      await _repository.updateSessionCount(
        session.id,
        actualCount,
        targetCount: state.targetCount,
      );

      if (!_disposed) {
        state = state.copyWith(
          sessionId: session.id,
          baselineCount: baseline,
          displayCount: newDisplayCount,
          savedCount: actualCount,
          pendingCount: 0,
          isSyncing: false,
          isCompleted: newDisplayCount >= state.targetCount,
        );
      }

      // Update global daily streak (Duolingo-style threshold) and capture event
      final streakUpdate = await _repository.updateDailyStreak(
        userId: _sessionParams.userId,
        date: _sessionParams.sessionDate ?? DateTime.now(),
      );
      if (!_disposed && streakUpdate != null) {
        state = state.copyWith(streakUpdate: streakUpdate);
      }

      await _checkPlanProgressIfNeeded();
    } catch (e) {
      if (!_disposed) {
        // Keep the display count but mark sync error
        state = state.copyWith(isSyncing: false);
      }
    }
  }

  Future<void> syncOnExit() async {
    _autoSaveTimer?.cancel();
    await _syncToDatabase();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  StreakUpdate? takeStreakUpdate() {
    final update = state.streakUpdate;
    if (!_disposed && update != null) {
      state = state.copyWith(streakUpdate: null);
    }
    return update;
  }

  Future<void> _checkPlanProgressIfNeeded() async {
    if (_isSyncingPlan) return;
    final goalId = _sessionParams.planGoalId;
    final goalSessionId = _sessionParams.goalSessionId;
    if (goalId == null || goalSessionId == null) return;
    if (state.displayCount < state.targetCount) return;

    _isSyncingPlan = true;
    try {
      await _repository.markPlannerDayCompleted(
        goalId: goalId,
        userId: _sessionParams.userId,
      );
    } finally {
      _isSyncingPlan = false;
    }
  }
}

// Provider for initial counter state
final counterInitialStateProvider = FutureProvider.autoDispose
    .family<CounterState, SessionParams>((ref, sessionParams) async {
      final repository = ref.watch(tasbihRepositoryProvider);

      final session = await repository.getOrCreateSession(
        userId: sessionParams.userId,
        collectionId: sessionParams.collectionId,
        dhikrItemId: sessionParams.dhikrItemId,
        targetCount: sessionParams.targetCount,
        sessionDate: sessionParams.sessionDate,
        goalSessionId: sessionParams.goalSessionId,
      );

      final storedBaseline = await CounterBaselineStore.readBaseline(
        session.id,
      );
      final clampedBaseline = storedBaseline.clamp(0, session.count).toInt();
      final initialDisplay = (session.count - clampedBaseline)
          .clamp(0, session.count)
          .toInt();

      return CounterState(
        sessionId: session.id,
        displayCount: initialDisplay,
        savedCount: session.count,
        pendingCount: 0,
        targetCount: sessionParams.targetCount,
        baselineCount: clampedBaseline,
        isCompleted: initialDisplay >= sessionParams.targetCount,
      );
    });

// Provider for the counter controller
final tasbihCounterControllerProvider = StateNotifierProvider.autoDispose
    .family<TasbihCounterController, CounterState, SessionParams>((
      ref,
      sessionParams,
    ) {
      final repository = ref.watch(tasbihRepositoryProvider);

      // Get initial state from FutureProvider
      final initialStateAsync = ref.watch(
        counterInitialStateProvider(sessionParams),
      );

      final initialState =
          initialStateAsync.whenData((state) => state).value ??
          CounterState(
            sessionId: '',
            displayCount: 0,
            savedCount: 0,
            pendingCount: 0,
            targetCount: sessionParams.targetCount,
            baselineCount: 0,
            isCompleted: false,
          );

      return TasbihCounterController(repository, sessionParams, initialState);
    });

/// Wraps the counter controller state with the async lifecycle from the initial fetch.
final tasbihCounterUiStateProvider = Provider.autoDispose
    .family<AsyncValue<CounterState>, SessionParams>((ref, sessionParams) {
      final initialStateAsync = ref.watch(
        counterInitialStateProvider(sessionParams),
      );

      return initialStateAsync.when(
        data: (_) {
          final state = ref.watch(
            tasbihCounterControllerProvider(sessionParams),
          );
          return AsyncValue.data(state);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });
