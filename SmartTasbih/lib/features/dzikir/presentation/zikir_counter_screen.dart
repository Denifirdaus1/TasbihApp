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

    ref.listen<ZikirCounterState>(
      zikirCounterControllerProvider,
      (previous, next) {
        if (previous?.displayedCount == next.displayedCount) return;
        _triggerHaptic(strong: next.displayedCount % 33 == 0);
      },
    );
  }

  void _triggerHaptic({bool strong = false}) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih Progresif'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProgressCard(state: state),
          const SizedBox(height: 20),
          Text(
            'Target Sesi',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
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
            'Koleksi Zikir-mu',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget(
            value: collections,
            builder: (data) {
              if (data.isEmpty) {
                return const Text(
                    'Belum ada koleksi. Tambahkan via Supabase atau modul manajemen.');
              }
              return Column(
                children: data
                    .map(
                      (item) => _CollectionTile(item: item),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        heroTag: 'zikirFab',
        onPressed: () => ref
            .read(zikirCounterControllerProvider.notifier)
            .increment(),
        child: const Icon(Icons.touch_app),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final ZikirCounterState state;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hitungan Aktif',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatter.format(state.displayedCount),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pending: ${state.pendingCount}'),
                    if (state.lastSyncedAt != null)
                      Text(
                        'Sinkron ${DateFormat.Hm().format(state.lastSyncedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: state.progress.clamp(0, 1),
              minHeight: 12,
              borderRadius: BorderRadius.circular(12),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.redAccent),
              ),
            ],
          ],
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
            Text(
              'Target: ${item.targetCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
