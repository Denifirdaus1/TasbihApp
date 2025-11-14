import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _CounterBody extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final counterState = ref.watch(tasbihCounterUiStateProvider(sessionParams));

    return Scaffold(
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
        data: (state) => _buildCounterBody(context, ref, state),
      ),
    );
  }

  Widget _buildCounterBody(
    BuildContext context,
    WidgetRef ref,
    CounterState state,
  ) {
    final theme = Theme.of(context);
    final isCompleted = state.isCompleted;
    final progress = state.progress;

    return Column(
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
                AnimatedBuilder(
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
                            color: isCompleted ? Colors.green : collectionColor,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Main increment button
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: isCompleted
                      ? null
                      : () => _incrementCount(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? Colors.grey
                        : collectionColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isCompleted ? 0 : 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isCompleted) ...[
                        Icon(Icons.add_circle_outline, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'TAMBAH',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.check, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'SELESAI',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Control buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showCountInputDialog(context, ref, state),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Set Jumlah'),
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
    );
  }

  void _incrementCount(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();

    pulseController.forward().then((_) {
      pulseController.reverse();
    });

    final controller = ref.read(
      tasbihCounterControllerProvider(sessionParams).notifier,
    );
    final currentState = ref.read(
      tasbihCounterControllerProvider(sessionParams),
    );

    // Increment instantly (REAL-TIME!)
    controller.increment();

    // Show completion dialog if just reached target
    if (!currentState.isCompleted &&
        currentState.displayCount + 1 >= currentState.targetCount) {
      // Delay dialog slightly to allow animation
      Future.delayed(const Duration(milliseconds: 300), () {
        onShowCompletionDialog();
      });
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

  void _showCountInputDialog(
    BuildContext context,
    WidgetRef ref,
    CounterState currentState,
  ) {
    final controller = TextEditingController(
      text: currentState.displayCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Jumlah'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jumlah',
            hintText: '0-${dhikrItem.targetCount}',
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
              final count = int.tryParse(controller.text);
              if (count != null && count >= 0) {
                Navigator.of(context).pop();
                ref
                    .read(
                      tasbihCounterControllerProvider(sessionParams).notifier,
                    )
                    .setCount(count);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
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
