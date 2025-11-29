import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../domain/dhikr_item.dart';
import '../domain/tasbih_collection.dart';

import '../presentation/reminder_settings_screen.dart';
import '../presentation/tasbih_counter_screen.dart';
import 'tasbih_providers.dart';

class TasbihCollectionDetailScreen extends ConsumerStatefulWidget {
  const TasbihCollectionDetailScreen({
    super.key,
    required this.collection,
    this.attachedGoalId,
    this.attachedGoalTargetCount,
    this.attachedGoalSessionId,
  });

  final TasbihCollection collection;
  final String? attachedGoalId;
  final int? attachedGoalTargetCount;
  final String? attachedGoalSessionId;

  @override
  ConsumerState<TasbihCollectionDetailScreen> createState() =>
      _TasbihCollectionDetailScreenState();
}

class _TasbihCollectionDetailScreenState
    extends ConsumerState<TasbihCollectionDetailScreen> {
  late TasbihCollection _collection;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
  }

  @override
  Widget build(BuildContext context) {
    final dhikrItems = ref.watch(dhikrItemsProvider(_collection.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ReminderSettingsScreen(collection: _collection),
                ),
              );
            },
            tooltip: 'Atur Pengingat',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCollectionDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dhikrItemsProvider(_collection.id));
        },
        child: AsyncValueWidget(
          value: dhikrItems,
          builder: (items) {
            if (items.isEmpty) {
              return _EmptyDhikrState(
                collection: _collection,
                onAddDhikr: () => _showAddDhikrDialog(context, ref),
              );
            }

            return Column(
              children: [
                if (widget.attachedGoalId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _AttachedPlanBanner(
                      targetCount: widget.attachedGoalTargetCount,
                    ),
                  ),
                _CollectionHeader(collection: _collection),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _DhikrItemCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TasbihCounterScreen(
                                dhikrItem: item,
                                collection: _collection,
                                attachedGoalId: widget.attachedGoalId,
                                attachedGoalTargetCount:
                                    widget.attachedGoalTargetCount,
                                attachedGoalSessionId:
                                    widget.attachedGoalSessionId,
                              ),
                            ),
                          );
                        },
                        onEdit: () => _showEditDhikrDialog(context, ref, item),
                        onDelete: () =>
                            _showDeleteDhikrDialog(context, ref, item),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDhikrDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditCollectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final updatedCollection = await showDialog<TasbihCollection>(
      context: context,
      builder: (dialogContext) => EditCollectionDialog(collection: _collection),
    );

    if (updatedCollection != null) {
      if (!mounted) return;
      setState(() => _collection = updatedCollection);
      ref.invalidate(collectionsProvider);
      ref.invalidate(dhikrItemsProvider(_collection.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koleksi berhasil diperbarui')),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Koleksi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus koleksi "${_collection.name}"? Semua dzikir di dalamnya juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await deleteCollectionAction(ref, collectionId: _collection.id);

              if (!context.mounted) return;

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Koleksi berhasil dihapus')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddDhikrDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddDhikrDialog(
        collectionId: _collection.id,
        onDhikrAdded: () {
          Navigator.of(context).pop();
          ref.invalidate(dhikrItemsProvider(_collection.id));
        },
      ),
    );
  }

  void _showEditDhikrDialog(
    BuildContext context,
    WidgetRef ref,
    DhikrItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditDhikrDialog(
        collectionId: _collection.id,
        item: item,
        onDhikrUpdated: () {
          Navigator.of(context).pop();
          ref.invalidate(dhikrItemsProvider(_collection.id));
        },
      ),
    );
  }

  void _showDeleteDhikrDialog(
    BuildContext context,
    WidgetRef ref,
    DhikrItem item,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Dzikir'),
        content: Text(
          'Apakah Anda yakin ingin menghapus dzikir "${item.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await deleteDhikrItemAction(ref, itemId: item.id);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dzikir berhasil dihapus')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.collection});

  final TasbihCollection collection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collectionColor = _getColor(collection.color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: collectionColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: collectionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(collection.icon),
                  color: collectionColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            collection.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: collectionColor,
                            ),
                          ),
                        ),
                        if (collection.isSwitchMode &&
                            collection.timePeriod != null)
                          _TimePeriodSwitch(collection: collection),
                      ],
                    ),
                    if (collection.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _getCollectionTypeIcon(collection.type),
                size: 16,
                color: collectionColor,
              ),
              const SizedBox(width: 4),
              Text(
                _getCollectionTypeLabel(collection.type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: collectionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCollectionTypeIcon(TasbihCollectionType type) {
    switch (type) {
      case TasbihCollectionType.prayerTimes:
        return Icons.access_time;
      case TasbihCollectionType.timeBased:
        return Icons.schedule;
      case TasbihCollectionType.free:
        return Icons.radio_button_unchecked;
    }
  }

  String _getCollectionTypeLabel(TasbihCollectionType type) {
    switch (type) {
      case TasbihCollectionType.prayerTimes:
        return 'Setelah Sholat';
      case TasbihCollectionType.timeBased:
        return 'Dzikir Waktu';
      case TasbihCollectionType.free:
        return 'Bebas';
    }
  }
}

class _AttachedPlanBanner extends StatelessWidget {
  const _AttachedPlanBanner({this.targetCount});

  final int? targetCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.flag, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terhubung ke Dzikir Plan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target harian: ${targetCount ?? '-'}x dzikir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePeriodSwitch extends ConsumerWidget {
  const _TimePeriodSwitch({required this.collection});

  final TasbihCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionColor = _getColor(collection.color);
    final isPagi = collection.timePeriod == TimePeriod.pagi;

    return Container(
      decoration: BoxDecoration(
        color: collectionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: collectionColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimePeriodButton(
            text: 'Pagi',
            isSelected: isPagi,
            onTap: () => _toggleTimePeriod(ref, context, TimePeriod.pagi),
            activeColor: Colors.orange,
            collectionColor: collectionColor,
          ),
          _TimePeriodButton(
            text: 'Petang',
            isSelected: !isPagi,
            onTap: () => _toggleTimePeriod(ref, context, TimePeriod.petang),
            activeColor: Colors.indigo,
            collectionColor: collectionColor,
          ),
        ],
      ),
    );
  }

  void _toggleTimePeriod(
    WidgetRef ref,
    BuildContext context,
    TimePeriod period,
  ) {
    if (collection.timePeriod == period) return;

    // Call repository to update
    ref
        .read(tasbihRepositoryProvider)
        .updateCollection(collection.id, timePeriod: period)
        .then((_) {
          // Invalidate provider to refresh UI
          ref.invalidate(collectionsProvider);
          ref.invalidate(collectionDetailProvider(collection.id));
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengubah waktu: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }
}

class _TimePeriodButton extends StatelessWidget {
  const _TimePeriodButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.collectionColor,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color collectionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? Colors.white
                : collectionColor.withValues(alpha: 0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Color _getColor(String colorHex) {
  try {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  } catch (e) {
    return Colors.green;
  }
}

IconData _getIconData(String iconName) {
  switch (iconName) {
    case 'radio_button_checked':
      return Icons.radio_button_checked;
    case 'access_time':
      return Icons.access_time;
    case 'favorite':
      return Icons.favorite;
    case 'star':
      return Icons.star;
    case 'bookmark':
      return Icons.bookmark;
    case 'wb_twilight':
      return Icons.wb_twilight;
    case 'wb_sunny':
      return Icons.wb_sunny;
    case 'wb_cloudy':
      return Icons.wb_cloudy;
    case 'nights_stay':
      return Icons.nights_stay;
    case 'brightness_3':
      return Icons.brightness_3;
    default:
      return Icons.radio_button_checked;
  }
}

class _DhikrItemCard extends StatelessWidget {
  const _DhikrItemCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DhikrItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${item.targetCount} kali',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDhikrState extends StatelessWidget {
  const _EmptyDhikrState({required this.collection, required this.onAddDhikr});

  final TasbihCollection collection;
  final VoidCallback onAddDhikr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.format_list_bulleted_add,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Dzikir',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tambahkan dzikir pertama ke koleksi "${collection.name}" untuk memulai.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddDhikr,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Dzikir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddDhikrDialog extends ConsumerStatefulWidget {
  const AddDhikrDialog({
    super.key,
    required this.collectionId,
    required this.onDhikrAdded,
  });

  final String collectionId;
  final VoidCallback onDhikrAdded;

  @override
  ConsumerState<AddDhikrDialog> createState() => _AddDhikrDialogState();
}

class _AddDhikrDialogState extends ConsumerState<AddDhikrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _targetCountController = TextEditingController(text: '33');

  @override
  void dispose() {
    _textController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dhikrController = ref.watch(createDhikrItemProvider);

    return AlertDialog(
      title: const Text('Tambah Dzikir'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Teks Dzikir',
                hintText: 'contoh: Alhamdulillah',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Teks dzikir tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetCountController,
              decoration: const InputDecoration(
                labelText: 'Target Jumlah',
                hintText: 'contoh: 33',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Target jumlah tidak boleh kosong';
                }
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: dhikrController.isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: dhikrController.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final targetCount = int.parse(_targetCountController.text);
                  await createDhikrItemAction(
                    ref,
                    collectionId: widget.collectionId,
                    text: _textController.text.trim(),
                    targetCount: targetCount,
                  );

                  if (!context.mounted) return;

                  final latestController = ref.read(createDhikrItemProvider);

                  if (latestController.hasValue &&
                      !latestController.isLoading) {
                    widget.onDhikrAdded();
                  } else if (latestController.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${latestController.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: dhikrController.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tambah'),
        ),
      ],
    );
  }
}

class EditDhikrDialog extends ConsumerStatefulWidget {
  const EditDhikrDialog({
    super.key,
    required this.collectionId,
    required this.item,
    required this.onDhikrUpdated,
  });

  final String collectionId;
  final DhikrItem item;
  final VoidCallback onDhikrUpdated;

  @override
  ConsumerState<EditDhikrDialog> createState() => _EditDhikrDialogState();
}

class _EditDhikrDialogState extends ConsumerState<EditDhikrDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _targetCountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
    _targetCountController = TextEditingController(
      text: widget.item.targetCount.toString(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateDhikrItemProvider);

    return AlertDialog(
      title: const Text('Edit Dzikir'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Teks Dzikir',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Teks dzikir tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetCountController,
              decoration: const InputDecoration(
                labelText: 'Target Jumlah',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Target jumlah tidak boleh kosong';
                }
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: updateState.isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: updateState.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final targetCount =
                      int.tryParse(_targetCountController.text) ??
                      widget.item.targetCount;

                  try {
                    await updateDhikrItemAction(
                      ref,
                      collectionId: widget.collectionId,
                      itemId: widget.item.id,
                      text: _textController.text.trim(),
                      targetCount: targetCount,
                    );

                    if (!context.mounted) return;
                    widget.onDhikrUpdated();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memperbarui dzikir: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: updateState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class EditCollectionDialog extends ConsumerStatefulWidget {
  const EditCollectionDialog({super.key, required this.collection});

  final TasbihCollection collection;

  @override
  ConsumerState<EditCollectionDialog> createState() =>
      _EditCollectionDialogState();
}

class _EditCollectionDialogState extends ConsumerState<EditCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedColor;

  final _colors = const [
    '#4CAF50',
    '#2196F3',
    '#FF9800',
    '#F44336',
    '#9C27B0',
    '#795548',
    '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(
      text: widget.collection.description ?? '',
    );
    _selectedColor = widget.collection.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updateState = ref.watch(updateCollectionProvider);

    return AlertDialog(
      title: const Text('Edit Koleksi'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Koleksi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama koleksi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Warna', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(color.replaceFirst('#', '0xFF')),
                        ),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: updateState.isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: updateState.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  try {
                    final updated = await updateCollectionAction(
                      ref,
                      collectionId: widget.collection.id,
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                      color: _selectedColor,
                    );

                    if (!context.mounted) return;
                    Navigator.of(context).pop(updated);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memperbarui koleksi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: updateState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
