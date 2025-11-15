import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;

import '../../../core/notifications/notification_service.dart';
import '../../../core/providers/global_providers.dart';
import '../data/zikir_repository.dart';
import '../domain/zikir_models.dart';

class ZikirCounterState {
  const ZikirCounterState({
    required this.totalCount,
    required this.pendingCount,
    required this.sessionTarget,
    this.isSyncing = false,
    this.errorMessage,
    this.lastSyncedAt,
  });

  final int totalCount;
  final int pendingCount;
  final int sessionTarget;
  final bool isSyncing;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  int get displayedCount => totalCount + pendingCount;

  double get progress {
    final remainder = displayedCount % sessionTarget;
    return remainder / sessionTarget;
  }

  ZikirCounterState copyWith({
    int? totalCount,
    int? pendingCount,
    int? sessionTarget,
    bool? isSyncing,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return ZikirCounterState(
      totalCount: totalCount ?? this.totalCount,
      pendingCount: pendingCount ?? this.pendingCount,
      sessionTarget: sessionTarget ?? this.sessionTarget,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  factory ZikirCounterState.initial() => const ZikirCounterState(
        totalCount: 0,
        pendingCount: 0,
        sessionTarget: 100,
      );
}

final zikirRepositoryProvider = Provider<ZikirRepository>(
  (ref) => ZikirRepository(ref.watch(supabaseClientProvider)),
);

final zikirCounterControllerProvider = StateNotifierProvider.autoDispose<
    ZikirCounterController, ZikirCounterState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return ZikirCounterController(
    repository: ref.watch(zikirRepositoryProvider),
    userId: userId,
  );
});

final userZikirCollectionsProvider =
    FutureProvider<List<UserZikirCollection>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  return ref.watch(zikirRepositoryProvider).fetchCollections(userId);
});

class ZikirCounterController extends StateNotifier<ZikirCounterState> {
  ZikirCounterController({
    required ZikirRepository repository,
    required this.userId,
  })  : _repository = repository,
        super(ZikirCounterState.initial());

  final ZikirRepository _repository;
  final String? userId;
  Timer? _debounceTimer;
  static const int _batchSize = 10;
  static const Duration _debounceDuration = Duration(seconds: 3);

  void increment({bool fromVolumeButton = false}) {
    state = state.copyWith(
      pendingCount: state.pendingCount + 1,
      errorMessage: null,
    );

    if (state.pendingCount >= _batchSize) {
      unawaited(syncNow());
    } else {
      _scheduleDebounce();
    }

    final displayCount = state.displayedCount;
    if (displayCount % 33 == 0 || displayCount % state.sessionTarget == 0) {
      final title = fromVolumeButton ? 'Tasbih Volume' : 'Progres SmartTasbih';
      NotificationService.showCelebration(
        title,
        'Target mikro tercapai ($displayCount).',
      );
    }
  }

  void setSessionTarget(int target) {
    state = state.copyWith(sessionTarget: target);
  }

  
  void _scheduleDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    if (state.pendingCount == 0 || userId == null) return;

    final amount = state.pendingCount;
    _debounceTimer?.cancel();
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _repository.incrementGoalCount(
        userId: userId!,
        amount: amount,
      );
      state = state.copyWith(
        totalCount: state.totalCount + amount,
        pendingCount: 0,
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> syncOnExit() async {
    await syncNow();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
