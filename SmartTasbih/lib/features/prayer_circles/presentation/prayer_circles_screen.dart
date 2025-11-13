import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../dzikir/presentation/zikir_counter_controller.dart';
import '../domain/prayer_circle_models.dart';
import 'prayer_circle_providers.dart';

class PrayerCirclesScreen extends ConsumerWidget {
  const PrayerCirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(prayerCirclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lingkaran Doa'),
      ),
      body: AsyncValueWidget(
        value: circles,
        builder: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups, size: 64),
                  const SizedBox(height: 12),
                  const Text('Belum ada Lingkaran. Buat atau gabung dengan kode.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final circle = items[index];
              return _CircleCard(circle: circle);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Buat Circle'),
              onTap: () {
                Navigator.pop(context);
                _showCreateCircleDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Gabung via Kode'),
              onTap: () {
                Navigator.pop(context);
                _showJoinCircleDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCircleDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Circle'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Circle',
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Wajib diisi' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(prayerCircleRepositoryProvider).createCircle(
                    name: controller.text.trim(),
                    userId: user.id,
                  );
              ref.invalidate(prayerCirclesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinCircleDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masuk dengan Kode'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Kode Undangan',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) =>
                value == null || value.length < 6 ? 'Kode tidak valid' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref.read(prayerCircleRepositoryProvider).joinByCode(
                      inviteCode: controller.text.trim().toUpperCase(),
                      userId: user.id,
                    );
                ref.invalidate(prayerCirclesProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              }
            },
            child: const Text('Gabung'),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends ConsumerWidget {
  const _CircleCard({required this.circle});

  final PrayerCircle circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(circleGoalsStreamProvider(circle.id));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  circle.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  circle.inviteCode,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: goals,
              builder: (data) {
                if (data.isEmpty) {
                  return TextButton.icon(
                    onPressed: () => _showCreateGoalDialog(context, ref, circle),
                    icon: const Icon(Icons.flag),
                    label: const Text('Buat Target Zikir'),
                  );
                }
                return Column(
                  children: data
                      .map(
                        (goal) => _GoalTile(circle: circle, goal: goal),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showCreateGoalDialog(context, ref, circle),
                child: const Text('Tambah Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGoalDialog(
      BuildContext context, WidgetRef ref, PrayerCircle circle) {
    final targetController = TextEditingController(text: '1000');
    final zikirIdController = TextEditingController();
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Target Baru - ${circle.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: zikirIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID Zikir',
                helperText: 'Gunakan id dari tabel zikir_master',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Hitungan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final target = int.tryParse(targetController.text) ?? 0;
              final zikirId = int.tryParse(zikirIdController.text);
              if (target <= 0 || zikirId == null) return;
              await ref.read(prayerCircleRepositoryProvider).createGoal(
                    circleId: circle.id,
                    userId: user.id,
                    target: target,
                    zikirId: zikirId,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({
    required this.circle,
    required this.goal,
  });

  final PrayerCircle circle;
  final CircleGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = goal.targetCount == 0
        ? 0.0
        : (goal.currentCount / goal.targetCount).clamp(0.0, 1.0).toDouble();
    return Card(
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(goal.zikirName ?? 'Zikir ID ${goal.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${goal.currentCount} / ${goal.targetCount}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent.isNaN ? 0 : percent,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          tooltip: 'Fokuskan di Tasbih',
          onPressed: () {
            ref
                .read(zikirCounterControllerProvider.notifier)
                .selectCircleGoal(goal.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Goal ${goal.zikirName ?? goal.id} aktif di halaman Tasbih'),
              ),
            );
          },
        ),
      ),
    );
  }
}
