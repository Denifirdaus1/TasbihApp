import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import '../data/tasbih_repository.dart';
import 'tasbih_providers.dart';

class CounterState {
  final int displayCount;
  final int savedCount;
  final int pendingCount;
  final int targetCount;
  final bool isCompleted;
  final bool isSyncing;

  const CounterState({
    required this.displayCount,
    required this.savedCount,
    required this.pendingCount,
    required this.targetCount,
    this.isCompleted = false,
    this.isSyncing = false,
  });

  double get progress => displayCount / targetCount;

  CounterState copyWith({
    int? displayCount,
    int? savedCount,
    int? pendingCount,
    int? targetCount,
    bool? isCompleted,
    bool? isSyncing,
  }) {
    return CounterState(
      displayCount: displayCount ?? this.displayCount,
      savedCount: savedCount ?? this.savedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      targetCount: targetCount ?? this.targetCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isSyncing: isSyncing ?? this.isSyncing,
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

    state = state.copyWith(
      displayCount: count,
      pendingCount: count - state.savedCount,
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
      );

      await _repository.updateSessionTarget(
        session.id,
        targetCount,
        currentCount: state.displayCount,
      );

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
    state = state.copyWith(
      displayCount: 0,
      pendingCount: -state.savedCount,
      isCompleted: false,
      isSyncing: true,
    );

    await _syncToDatabase(forceCount: 0);
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
      );

      final newCount = forceCount ?? state.displayCount;
      await _repository.updateSessionCount(session.id, newCount);

      if (!_disposed) {
        state = state.copyWith(
          savedCount: newCount,
          pendingCount: 0,
          isSyncing: false,
        );
      }
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
      );

      return CounterState(
        displayCount: session.count,
        savedCount: session.count,
        pendingCount: 0,
        targetCount: sessionParams.targetCount,
        isCompleted: session.count >= sessionParams.targetCount,
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
            displayCount: 0,
            savedCount: 0,
            pendingCount: 0,
            targetCount: sessionParams.targetCount,
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
