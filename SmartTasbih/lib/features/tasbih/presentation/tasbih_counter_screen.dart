import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../../core/providers/global_providers.dart';
import '../domain/dhikr_item.dart';
import '../domain/tasbih_collection.dart';
import '../presentation/tasbih_counter_controller.dart';
import '../presentation/tasbih_providers.dart';

class TasbihCounterScreen extends ConsumerStatefulWidget {
  const TasbihCounterScreen({
    super.key,
    required this.dhikrItem,
    required this.collection,
  });

  final DhikrItem dhikrItem;
  final TasbihCollection collection;

  @override
  ConsumerState<TasbihCounterScreen> createState() =>
      _TasbihCounterScreenState();
}

class _TasbihCounterScreenState extends ConsumerState<TasbihCounterScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  SessionParams? _sessionParams;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Sync remaining counts before leaving
    final params = _sessionParams;
    if (params != null) {
      ref.read(tasbihCounterControllerProvider(params).notifier).syncOnExit();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Sync when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final params = _sessionParams;
      if (params != null) {
        ref.read(tasbihCounterControllerProvider(params).notifier).syncOnExit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    final sessionParams = SessionParams(
      userId: userId,
      collectionId: widget.collection.id,
      dhikrItemId: widget.dhikrItem.id,
      targetCount: widget.dhikrItem.targetCount,
    );
    _sessionParams = sessionParams;

    return _CounterBody(
      collection: widget.collection,
      dhikrItem: widget.dhikrItem,
      collectionColor: _getCollectionColor(),
      sessionParams: sessionParams,
      onShowCompletionDialog: _showCompletionDialog,
      pulseController: _pulseController,
      pulseAnimation: _pulseAnimation,
    );
  }

  Color _getCollectionColor() {
    try {
      return Color(
        int.parse(widget.collection.color.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      return Colors.green;
    }
  }
}

class _CounterBody extends ConsumerStatefulWidget {
  const _CounterBody({
    required this.collection,
    required this.dhikrItem,
    required this.collectionColor,
    required this.sessionParams,
    required this.onShowCompletionDialog,
    required this.pulseController,
    required this.pulseAnimation,
  });

  final TasbihCollection collection;
  final DhikrItem dhikrItem;
  final Color collectionColor;
  final SessionParams sessionParams;
  final VoidCallback onShowCompletionDialog;
  final AnimationController pulseController;
  final Animation<double> pulseAnimation;

  @override
  ConsumerState<_CounterBody> createState() => _CounterBodyState();
}

class _CounterBodyState extends ConsumerState<_CounterBody> {
  bool _isHapticEnabled = true;
  bool _isGlobalTapEnabled = false;
  bool _hasVibrator = false;
  bool _isSyncingBeforeExit = false;
  final GlobalKey _controlsAreaKey = GlobalKey();

  TasbihCollection get collection => widget.collection;
  DhikrItem get dhikrItem => widget.dhikrItem;
  Color get collectionColor => widget.collectionColor;
  SessionParams get sessionParams => widget.sessionParams;
  VoidCallback get onShowCompletionDialog => widget.onShowCompletionDialog;
  AnimationController get pulseController => widget.pulseController;
  Animation<double> get pulseAnimation => widget.pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkVibrationSupport();
  }

  void _checkVibrationSupport() {
    Vibration.hasVibrator().then((value) {
      if (!mounted) return;
      setState(() {
        _hasVibrator = value == true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterState =
        ref.watch(tasbihCounterUiStateProvider(sessionParams));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _syncPendingChanges();
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text(collection.name),
        backgroundColor: collectionColor.withValues(alpha: 0.1),
        actions: [
          // Show sync indicator when syncing
          counterState.whenOrNull(
                data: (state) => state.isSyncing
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : state.pendingCount > 0
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${state.pendingCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ) ??
              const SizedBox(),
        ],
      ),
        body: counterState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (state) => _buildCounterBody(context, state),
        ),
      ),
    );
  }

  Widget _buildCounterBody(
    BuildContext context,
    CounterState state,
  ) {
    final theme = Theme.of(context);
    final isCompleted = state.isCompleted;
    final progress = state.progress;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _isGlobalTapEnabled && !isCompleted
          ? (details) {
              if (_shouldHandleGlobalTap(details.globalPosition)) {
                _incrementCount(context, ref);
              }
            }
          : null,
      child: Column(
        children: [
        // Header with dzikr text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: collectionColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: collectionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dhikrItem.text,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: collectionColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, color: collectionColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Target: ${state.targetCount}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: collectionColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Progress section
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : collectionColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.displayCount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: collectionColor,
                    ),
                  ),
                  Text(
                    '${state.targetCount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Counter display
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: !_isGlobalTapEnabled && !isCompleted
                      ? () => _incrementCount(context, ref)
                      : null,
                  child: AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: pulseAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.1)
                                : collectionColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color:
                                  isCompleted ? Colors.green : collectionColor,
                              width: 4,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.displayCount.toString(),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 56,
                                  color: isCompleted
                                      ? Colors.green
                                      : collectionColor,
                                ),
                              ),
                              Text(
                                '/ ${state.targetCount}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                if (isCompleted) ...[
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Selesai! 🎉',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target dzikir hari ini telah tercapai',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    '${((progress * 100).round())}% Selesai',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.titleMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Control buttons
        Padding(
          key: _controlsAreaKey,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isHapticEnabled = !_isHapticEnabled;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isHapticEnabled
                            ? collectionColor
                            : theme.colorScheme.surface,
                        foregroundColor: _isHapticEnabled
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isHapticEnabled ? 2 : 0,
                      ),
                      icon: Icon(
                        _isHapticEnabled
                            ? Icons.vibration
                            : Icons.vibration_outlined,
                      ),
                      label: Text(
                        _isHapticEnabled ? 'Getar ON' : 'Getar OFF',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isGlobalTapEnabled = !_isGlobalTapEnabled;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isGlobalTapEnabled
                            ? collectionColor
                            : theme.colorScheme.surface,
                        foregroundColor: _isGlobalTapEnabled
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isGlobalTapEnabled ? 2 : 0,
                      ),
                      icon: Icon(
                        _isGlobalTapEnabled
                            ? Icons.touch_app
                            : Icons.touch_app_outlined,
                      ),
                      label: Text(
                        _isGlobalTapEnabled
                            ? 'Tap Layar ON'
                            : 'Tap Layar OFF',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Control buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showTargetInputDialog(context, ref, state),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Ubah Target'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.displayCount > 0
                          ? () => _resetCount(context, ref)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  void _incrementCount(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      tasbihCounterControllerProvider(sessionParams).notifier,
    );
    final currentState = ref.read(
      tasbihCounterControllerProvider(sessionParams),
    );

    final willComplete = !currentState.isCompleted &&
        currentState.displayCount + 1 >= currentState.targetCount;

    _triggerHaptic(strong: willComplete);

    pulseController.forward().then((_) {
      pulseController.reverse();
    });

    // Increment instantly (REAL-TIME!)
    controller.increment();

    // Show completion dialog if just reached target
    if (willComplete) {
      // Delay dialog slightly to allow animation
      Future.delayed(const Duration(milliseconds: 300), () {
        onShowCompletionDialog();
      });
    }
  }

  void _triggerHaptic({bool strong = false}) {
    if (!_isHapticEnabled) {
      return;
    }
    if (_hasVibrator) {
      Vibration.vibrate(
        duration: strong ? 120 : 40,
        amplitude: strong ? 200 : 120,
      );
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _resetCount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Counter?'),
        content: const Text('Apakah Anda yakin ingin mereset hitungan ke 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(tasbihCounterControllerProvider(sessionParams).notifier)
                  .reset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showTargetInputDialog(
    BuildContext context,
    WidgetRef ref,
    CounterState currentState,
  ) {
    final controller = TextEditingController(
      text: currentState.targetCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Target Tasbih'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Target baru',
            hintText:
                'Masukkan target lebih besar dari ${currentState.targetCount}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final target = int.tryParse(controller.text);
              if (target != null && target > 0) {
                Navigator.of(context).pop();
                ref
                    .read(
                      tasbihCounterControllerProvider(sessionParams).notifier,
                    )
                    .updateTarget(target);
              }
            },
            child: const Text('Simpan Target'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncPendingChanges() async {
    if (_isSyncingBeforeExit) {
      return;
    }
    final counterState = ref.read(
      tasbihCounterControllerProvider(sessionParams),
    );
    if (counterState.pendingCount <= 0) {
      return;
    }
    _isSyncingBeforeExit = true;
    try {
      await ref
          .read(tasbihCounterControllerProvider(sessionParams).notifier)
          .syncOnExit();
    } finally {
      _isSyncingBeforeExit = false;
    }
  }

  bool _shouldHandleGlobalTap(Offset globalPosition) {
    if (!_isGlobalTapEnabled) {
      return false;
    }
    return !_isPointInsideControls(globalPosition);
  }

  bool _isPointInsideControls(Offset globalPosition) {
    final context = _controlsAreaKey.currentContext;
    if (context == null) {
      return false;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }
    final topLeft = renderBox.localToGlobal(Offset.zero);
    final bottomRight = topLeft + Offset(renderBox.size.width, renderBox.size.height);
    return globalPosition.dx >= topLeft.dx &&
        globalPosition.dx <= bottomRight.dx &&
        globalPosition.dy >= topLeft.dy &&
        globalPosition.dy <= bottomRight.dy;
  }
}

// Extension on _TasbihCounterScreenState for completion dialog
extension on _TasbihCounterScreenState {
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Masya Allah! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Target dzikir "${widget.dhikrItem.text}" telah selesai!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Semoga Allah menerima amalan ibadah Anda.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to collection
            },
            child: const Text('Kembali ke Koleksi'),
          ),
        ],
      ),
    );
  }
}
