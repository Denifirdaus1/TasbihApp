import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../domain/tasbih_collection.dart';
import 'tasbih_collection_detail_screen.dart';
import 'tasbih_providers.dart';

class TasbihCollectionsScreen extends ConsumerWidget {
  const TasbihCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Tasbih'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCollectionDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collectionsProvider);
        },
        child: AsyncValueWidget(
          value: collections,
          builder: (collectionsList) {
            if (collectionsList.isEmpty) {
              return _EmptyState(
                onCreateCollection: () =>
                    _showCreateCollectionDialog(context, ref),
                onCreateDefaultCollections: () =>
                    _createDefaultCollections(context, ref),
              );
            }

            // Separate collections by type
            final timeBasedCollections = collectionsList
                .where((c) => c.type == TasbihCollectionType.timeBased)
                .toList();
            final prayerTimeCollections = collectionsList
                .where((c) => c.type == TasbihCollectionType.prayerTimes)
                .toList();
            final customCollections = collectionsList
                .where((c) => c.type == TasbihCollectionType.free)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Time-Based Section (Pagi/Petang)
                _SectionWithDropdown(
                  title: 'Dzikir Waktu',
                  subtitle: 'Dzikir pagi dan petang dengan mode switch',
                  icon: Icons.access_time,
                  iconColor: Theme.of(context).colorScheme.primary,
                  collections: timeBasedCollections,
                  onTap: (collection) => _navigateToDetail(context, collection),
                  onEmpty: timeBasedCollections.isEmpty
                      ? () => _createTimeBasedCollection(context, ref)
                      : null,
                  emptyMessage: 'Belum Ada Koleksi Dzikir Waktu',
                  emptyDescription: 'Buat koleksi dzikir pagi dan petang',
                ),

                const SizedBox(height: 24),

                // Prayer Times Section
                _SectionWithDropdown(
                  title: 'Dzikir Setelah Sholat',
                  subtitle: 'Koleksi dzikir setelah sholat fardhu',
                  icon: Icons.mosque,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  collections: prayerTimeCollections,
                  onTap: (collection) => _navigateToDetail(context, collection),
                  onEmpty: prayerTimeCollections.isEmpty
                      ? () => _createDefaultCollections(context, ref)
                      : null,
                  emptyMessage: 'Belum Ada Koleksi Setelah Sholat',
                  emptyDescription: 'Buat koleksi dzikir default untuk 5 waktu sholat',
                ),

                const SizedBox(height: 24),

                // Custom Collections Section
                _SectionWithDropdown(
                  title: 'Koleksi Kustom',
                  subtitle: 'Koleksi dzikir personal',
                  icon: Icons.bookmark,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  collections: customCollections,
                  onTap: (collection) => _navigateToDetail(context, collection),
                  onEmpty: null,
                  showCreateButton: true,
                  onCreatePressed: () => _showCreateCollectionDialog(context, ref),
                  emptyMessage: 'Belum Ada Koleksi Kustom',
                  emptyDescription: 'Buat koleksi dzikir personal sesuai kebutuhan Anda',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, TasbihCollection collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TasbihCollectionDetailScreen(collection: collection),
      ),
    );
  }

  Future<void> _createDefaultCollections(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await createDefaultCollectionsAction(ref);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Koleksi setelah sholat berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createTimeBasedCollection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await createTimeBasedCollectionAction(ref);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Koleksi dzikir waktu berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateCollectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateCollectionDialog(
        onCollectionCreated: () {
          Navigator.of(context).pop();
          ref.invalidate(collectionsProvider);
        },
      ),
    );
  }
}

class _SectionWithDropdown extends ConsumerStatefulWidget {
  const _SectionWithDropdown({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.collections,
    required this.onTap,
    this.onEmpty,
    this.emptyMessage,
    this.emptyDescription,
    this.showCreateButton = false,
    this.onCreatePressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<TasbihCollection> collections;
  final Function(TasbihCollection) onTap;
  final VoidCallback? onEmpty;
  final String? emptyMessage;
  final String? emptyDescription;
  final bool showCreateButton;
  final VoidCallback? onCreatePressed;

  @override
  ConsumerState<_SectionWithDropdown> createState() => _SectionWithDropdownState();
}

class _SectionWithDropdownState extends ConsumerState<_SectionWithDropdown> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCollections = widget.collections.isNotEmpty;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with dropdown
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasCollections) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.collections.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          // Content (expandable)
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (hasCollections) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: widget.collections.map((collection) {
                    return _CollectionCard(
                      collection: collection,
                      onTap: () => widget.onTap(collection),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      widget.icon,
                      size: 48,
                      color: widget.iconColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.emptyMessage ?? 'Belum Ada Koleksi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.emptyDescription ?? 'Buat koleksi baru',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    if (widget.onEmpty != null || widget.showCreateButton) ...[
                      const SizedBox(height: 16),
                      if (widget.onEmpty != null)
                        FilledButton.icon(
                          onPressed: widget.onEmpty,
                          icon: const Icon(Icons.add),
                          label: Text(widget.title == 'Dzikir Waktu'
                              ? 'Buat Koleksi Waktu'
                              : widget.title == 'Dzikir Setelah Sholat'
                                  ? 'Buat Koleksi Sholat'
                                  : 'Buat Koleksi Kustom'),
                        ),
                      if (widget.showCreateButton && widget.onCreatePressed != null) ...[
                        if (widget.onEmpty != null) const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: widget.onCreatePressed,
                          icon: const Icon(Icons.add),
                          label: const Text('Kustom Baru'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final TasbihCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColor(collection.color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(collection.icon),
                color: _getColor(collection.color),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (collection.isSwitchMode && collection.timePeriod != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: collection.timePeriod == TimePeriod.pagi
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.indigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            collection.timePeriod!.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: collection.timePeriod == TimePeriod.pagi
                                  ? Colors.orange
                                  : Colors.indigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (collection.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      collection.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onCreateCollection,
    required this.onCreateDefaultCollections,
  });

  final VoidCallback onCreateCollection;
  final VoidCallback onCreateDefaultCollections;

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
                Icons.library_books,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Koleksi',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mulai perjalanan spiritual Anda dengan membuat koleksi dzikir.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateDefaultCollections,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Buat Koleksi Default'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCreateCollection,
              icon: const Icon(Icons.add),
              label: const Text('Buat Koleksi Kustom'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateCollectionDialog extends ConsumerStatefulWidget {
  const CreateCollectionDialog({super.key, required this.onCollectionCreated});

  final VoidCallback onCollectionCreated;

  @override
  ConsumerState<CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState
    extends ConsumerState<CreateCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  TasbihCollectionType _selectedType = TasbihCollectionType.free;
  String _selectedColor = '#4CAF50';
  final String _selectedIcon = 'radio_button_checked';

  final List<String> _colors = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createCollectionAsync = ref.watch(createCollectionProvider);

    return AlertDialog(
      title: const Text('Buat Koleksi Baru'),
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
                  hintText: 'contoh: Dzikir Pagi',
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
                  labelText: 'Deskripsi (Opsional)',
                  hintText: 'contoh: Kumpulan dzikir pagi dan sore',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Tipe Koleksi', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<TasbihCollectionType>(
                segments: const [
                  ButtonSegment(
                    value: TasbihCollectionType.free,
                    icon: Icon(Icons.all_inclusive),
                    label: Text('Bebas'),
                  ),
                  ButtonSegment(
                    value: TasbihCollectionType.timeBased,
                    icon: Icon(Icons.access_time),
                    label: Text('Waktu'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                _selectedType == TasbihCollectionType.free
                    ? 'Bisa dibaca kapan saja'
                    : 'Dzikir pagi/petang dengan switch',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
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
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
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
                          ? Icon(Icons.check, color: Colors.white, size: 16)
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
          onPressed: createCollectionAsync.isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: createCollectionAsync.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  await createCollectionAction(
                    ref,
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                    type: _selectedType,
                    color: _selectedColor,
                    icon: _selectedIcon,
                  );

                  if (!context.mounted) return;

                  final latestState = ref.read(createCollectionProvider);

                  if (latestState.hasValue && !latestState.isLoading) {
                    widget.onCollectionCreated();
                  } else if (latestState.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${latestState.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: createCollectionAsync.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Buat'),
        ),
      ],
    );
  }
}