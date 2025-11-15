import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:volume_watcher/volume_watcher.dart';

import '../../../core/widgets/arabic_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../domain/zikir_models.dart';
import 'zikir_counter_controller.dart';

class ZikirCounterScreen extends ConsumerStatefulWidget {
  const ZikirCounterScreen({super.key});

  @override
  ConsumerState<ZikirCounterScreen> createState() => _ZikirCounterScreenState();
}

class _ZikirCounterScreenState extends ConsumerState<ZikirCounterScreen>
    with WidgetsBindingObserver {
  int? _volumeListenerId;
  bool _isHapticEnabled = true;
  bool _isGlobalTapEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _volumeListenerId = VolumeWatcher.addListener((_) {
      ref
          .read(zikirCounterControllerProvider.notifier)
          .increment(fromVolumeButton: true);
      _triggerHaptic();
    });
  }

  void _triggerHaptic({bool strong = false}) {
    if (!_isHapticEnabled) return;
    Vibration.hasVibrator().then((canVibrate) {
      if (canVibrate != true) return;
      Vibration.vibrate(
        duration: strong ? 120 : 30,
        amplitude: strong ? 180 : 80,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_volumeListenerId != null) {
      VolumeWatcher.removeListener(_volumeListenerId);
    }
    ref.read(zikirCounterControllerProvider.notifier).syncOnExit();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(zikirCounterControllerProvider.notifier).syncOnExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zikirCounterControllerProvider);
    final collections = ref.watch(userZikirCollectionsProvider);

    ref.listen<ZikirCounterState>(zikirCounterControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.displayedCount == next.displayedCount) return;
      _triggerHaptic(strong: next.displayedCount % 33 == 0);
    });

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
      children: [
        _ProgressCard(state: state, onCircleTap: _incrementCounter),
        const SizedBox(height: 20),
        Text(
          'Target Sesi',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [33, 100, 1000].map((target) {
            final isSelected = state.sessionTarget == target;
            return ChoiceChip(
              label: Text('$target'),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(zikirCounterControllerProvider.notifier)
                  .setSessionTarget(target),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isSyncing
                    ? null
                    : () => ref
                          .read(zikirCounterControllerProvider.notifier)
                          .syncNow(),
                icon: state.isSyncing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Sinkron Sekarang'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Koleksi Aktif',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        AsyncValueWidget(
          value: collections,
          builder: (data) {
            if (data.isEmpty) {
              return const Text(
                'Belum ada koleksi zikir. Tambahkan dari menu Tasbih.',
              );
            }

            return Column(
              children: data
                  .map((item) => _CollectionTile(item: item))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tasbih Progresif')),
      body: Stack(
        children: [
          Positioned.fill(child: content),
          if (_isGlobalTapEnabled)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _incrementCounter,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildModeButtons(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _incrementCounter() {
    ref.read(zikirCounterControllerProvider.notifier).increment();
  }

  Widget _buildModeButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ModeToggleButton(
                    isActive: _isHapticEnabled,
                    icon: Icons.vibration,
                    label: 'Getar',
                    onPressed: () {
                      setState(() => _isHapticEnabled = !_isHapticEnabled);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeToggleButton(
                    isActive: _isGlobalTapEnabled,
                    icon: Icons.touch_app,
                    label: 'Tap layar',
                    onPressed: () {
                      setState(
                        () => _isGlobalTapEnabled = !_isGlobalTapEnabled,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mode tap layar akan menambah hitungan dengan sentuh di mana saja.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state, required this.onCircleTap});

  final ZikirCounterState state;
  final VoidCallback onCircleTap;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final sessionTarget = state.sessionTarget;
    final progressPercent = (state.progress * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hitungan Aktif',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: onCircleTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formatter.format(state.displayedCount),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/ $sessionTarget',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: state.progress.clamp(0, 1),
              minHeight: 12,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${progressPercent.toStringAsFixed(0)}% selesai'),
                Text('Pending: ${state.pendingCount}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sentuh lingkaran untuk menambah hitungan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (state.lastSyncedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sinkron ${DateFormat.Hm().format(state.lastSyncedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool isActive;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(' '),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        foregroundColor: isActive ? Colors.white : theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.item});

  final UserZikirCollection item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((item.master?.arabicText ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              ArabicText(
                item.master!.arabicText!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              item.master?.translation ?? 'Tanpa terjemahan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text('Target: ', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
