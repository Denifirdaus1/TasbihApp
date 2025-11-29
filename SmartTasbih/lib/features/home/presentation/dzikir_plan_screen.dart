import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../tasbih/domain/dhikr_item.dart';
import '../../tasbih/domain/dzikir_plan.dart';
import '../../tasbih/domain/dzikir_plan_session.dart';
import '../../tasbih/domain/tasbih_collection.dart';
import '../../tasbih/presentation/tasbih_counter_screen.dart';
import '../../tasbih/presentation/tasbih_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/domain/profile.dart';

class DzikirPlanScreen extends ConsumerWidget {
  const DzikirPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const _LoginRequiredState();
    }

    final profileValue = ref.watch(profileFutureProvider);
    final summaryValue = ref.watch(dzikirPlannerSummaryProvider);
    final todosValue = ref.watch(dailyDzikirTodosProvider);

    Future<void> refresh() async {
      ref.invalidate(profileFutureProvider);
      ref.invalidate(dzikirPlannerSummaryProvider);
      ref.invalidate(dailyDzikirTodosProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dzikir Todo List')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Todo'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: todosValue.when(
          data: (todos) => _PlannerContent(
            profileValue: profileValue,
            summaryValue: summaryValue,
            todos: todos,
            onTodoTap: (todo) => _openTodoCounter(context, ref, todo),
            onEditTodo: (todo) => _showEditTodoSheet(context, ref, todo),
            onDeleteTodo: (todo) => _confirmDeleteTodo(context, ref, todo),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _PlannerError(
            message: 'Gagal memuat data: $error',
            onRetry: refresh,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTodoSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _DzikirTodoFormSheet(),
    );
  }

  Future<void> _showEditTodoSheet(
    BuildContext context,
    WidgetRef ref,
    DzikirTodo todo,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DzikirTodoFormSheet(initialTodo: todo),
    );
  }

  Future<void> _confirmDeleteTodo(
    BuildContext context,
    WidgetRef ref,
    DzikirTodo todo,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Hapus Todo'),
            content: Text(
              'Yakin ingin menghapus todo "${todo.dhikrText}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await deleteDzikirTodoAction(ref, goalSessionId: todo.goalSessionId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todo berhasil dihapus')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus todo: $error')),
      );
    }
  }

  Future<void> _openTodoCounter(
    BuildContext context,
    WidgetRef ref,
    DzikirTodo todo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu')),
      );
      return;
    }

    if (todo.collectionId == null || todo.dhikrItemId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Todo belum memiliki dzikir yang valid')),
      );
      return;
    }

    try {
      final repository = ref.read(tasbihRepositoryProvider);
      final collection = await repository.fetchCollectionById(
        userId: userId,
        collectionId: todo.collectionId!,
      );
      final dhikrItem =
          await repository.fetchDhikrItemById(todo.dhikrItemId!);

      if (dhikrItem == null) {
        throw Exception('Dzikir tidak ditemukan');
      }

      if (!context.mounted) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => TasbihCounterScreen(
            dhikrItem: dhikrItem,
            collection: collection,
            attachedGoalId: todo.goalId,
            attachedGoalTargetCount: todo.targetCount,
            attachedGoalSessionId: todo.goalSessionId,
          ),
        ),
      );

      ref.invalidate(dailyDzikirTodosProvider);
      ref.invalidate(dzikirPlannerSummaryProvider);
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuka counter: $error')),
      );
    }
  }
}

class _PlannerContent extends StatelessWidget {
  const _PlannerContent({
    required this.profileValue,
    required this.summaryValue,
    required this.todos,
    required this.onTodoTap,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  final AsyncValue<Profile> profileValue;
  final AsyncValue<DzikirPlannerSummary?> summaryValue;
  final List<DzikirTodo> todos;
  final ValueChanged<DzikirTodo> onTodoTap;
  final ValueChanged<DzikirTodo> onEditTodo;
  final ValueChanged<DzikirTodo> onDeleteTodo;

  @override
  Widget build(BuildContext context) {
    final summary = summaryValue.asData?.value;
    final profile = profileValue.asData?.value;
    final streakCurrent = profile?.dailyStreakCurrent ?? 0;
    final streakLongest = profile?.dailyStreakLongest ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PlannerHeader(
          summary: summary,
          isLoading: summaryValue.isLoading,
          hasError: summaryValue.hasError,
          isProfileLoading: profileValue.isLoading,
          profileError: profileValue.whenOrNull(error: (e, _) => e),
          streakCurrent: streakCurrent,
          streakLongest: streakLongest,
        ),
        const SizedBox(height: 16),
        if (todos.isEmpty)
          const _EmptyTodoState()
        else
          ...List.generate(todos.length, (index) {
            final todo = todos[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == todos.length - 1 ? 0 : 12,
              ),
              child: _TodoTimelineItem(
                todo: todo,
                isFirst: index == 0,
                isLast: index == todos.length - 1,
                onTap: () => onTodoTap(todo),
                onEdit: () => onEditTodo(todo),
                onDelete: () => onDeleteTodo(todo),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({
    required this.summary,
    required this.isLoading,
    required this.hasError,
    required this.isProfileLoading,
    required this.profileError,
    required this.streakCurrent,
    required this.streakLongest,
  });

  final DzikirPlannerSummary? summary;
  final bool isLoading;
  final bool hasError;
   // Global streak from profile
  final bool isProfileLoading;
  final Object? profileError;
  final int streakCurrent;
  final int streakLongest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading || isProfileLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError || profileError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gagal memuat ringkasan/planner',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tarik ke bawah untuk mencoba lagi.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Belum Ada Planner',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan todo dzikir untuk memulai planner harianmu.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final summaryData = summary!;
    final progress = summaryData.progress.clamp(0.0, 1.0);
    final cardColor = theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;
    final secondaryText =
        theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Dzikir Hari Ini',
            style: theme.textTheme.titleMedium?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            '${summaryData.totalTodayCount}/${summaryData.totalDailyTarget}',
            style: theme.textTheme.displaySmall?.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Penuhi target harian ini (>=100) untuk mempertahankan streak global.',
            style: theme.textTheme.bodyMedium?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: textColor,
              backgroundColor: textColor.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PlannerStatChip(
                  icon: Icons.local_fire_department,
                  label: 'Streak Global',
                  value: '$streakCurrent hari',
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlannerStatChip(
                  icon: Icons.military_tech,
                  label: 'Terpanjang',
                  value: '$streakLongest hari',
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodoTimelineItem extends StatelessWidget {
  const _TodoTimelineItem({
    required this.todo,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DzikirTodo todo;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = todo.isCompleted;
    final progress = todo.progress.clamp(0.0, 1.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 2,
                      color: theme.dividerColor,
                    ),
                  ),
                ),
                if (isFirst)
                  Positioned(
                    left: 15,
                    top: 0,
                    height: 8,
                    child: Container(
                      width: 2,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                if (isLast)
                  Positioned(
                    left: 15,
                    bottom: -8,
                    height: 16,
                    child: Container(
                      width: 2,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                Positioned(
                  left: 15 - 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: completed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatSessionTime(todo.sessionTime),
                            style: theme.textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Icon(
                            completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: completed
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  onEdit();
                                  break;
                                case 'delete':
                                  onDelete();
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        todo.dhikrText,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (todo.collectionName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            todo.collectionName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${todo.todayCount}/${todo.targetCount} bacaan',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Text('Ketuk untuk mulai'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerError extends StatelessWidget {
  const _PlannerError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlannerStatChip extends StatelessWidget {
  const _PlannerStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color.withValues(alpha: 0.8),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTodoState extends StatelessWidget {
  const _EmptyTodoState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.fact_check, size: 56),
          const SizedBox(height: 16),
          Text(
            'Belum ada todo dzikir untuk hari ini',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol Tambah Todo untuk membuat jadwal dzikir harianmu.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _DzikirTodoFormSheet extends ConsumerStatefulWidget {
  const _DzikirTodoFormSheet({this.initialTodo});

  final DzikirTodo? initialTodo;

  bool get isEditing => initialTodo != null;

  @override
  ConsumerState<_DzikirTodoFormSheet> createState() =>
      _DzikirTodoFormSheetState();
}

class _DzikirTodoFormSheetState extends ConsumerState<_DzikirTodoFormSheet> {
  String? _collectionId;
  String? _dhikrItemId;
  late TimeOfDay _time;
  late final TextEditingController _targetController;
  late List<int> _selectedDays;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController();
    final todo = widget.initialTodo;
    if (todo != null) {
      _collectionId = todo.collectionId;
      _dhikrItemId = todo.dhikrItemId;
      _time = _parseTimeOfDay(todo.sessionTime) ?? TimeOfDay.now();
      _targetController.text = todo.targetCount.toString();
      _selectedDays = List<int>.from(
        todo.customDaysOfWeek?.isNotEmpty == true
            ? todo.customDaysOfWeek!
            : todo.effectiveDaysOfWeek,
      );
    } else {
      _time = TimeOfDay.now();
      _selectedDays = [1, 2, 3, 4, 5, 6, 7];
      _targetController.text = '';
    }
  }

  bool get _isEditing => widget.initialTodo != null;

  @override
  Widget build(BuildContext context) {
    final collectionsValue = ref.watch(collectionsProvider);
    final formState = _isEditing
        ? ref.watch(updateDzikirTodoProvider)
        : ref.watch(createDzikirTodoProvider);
    final isLoading = formState.isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: collectionsValue.when(
          data: (collections) {
            if (collections.isEmpty) {
              return const _EmptyCollectionsNotice();
            }

            final selectedCollection =
                _resolveSelectedCollection(collections);

            final dhikrItemsValue = ref.watch(
              dhikrItemsProvider(selectedCollection.id),
            );

            return dhikrItemsValue.when(
              data: (items) {
                if (items.isEmpty) {
                  return _CollectionWithoutDhikr(collection: selectedCollection);
                }
                final dhikrItem = _resolveSelectedDhikr(items);
                if (!_isEditing && _targetController.text.isEmpty) {
                  _targetController.text = dhikrItem.targetCount.toString();
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Todo Dzikir' : 'Tambah Todo Dzikir',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Pilih Koleksi',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _collectionId,
                          isExpanded: true,
                          items: collections
                              .map(
                                (collection) => DropdownMenuItem(
                                  value: collection.id,
                                  child: Text(collection.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _collectionId = value;
                              _dhikrItemId = null;
                              if (!_isEditing) {
                                _targetController.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Pilih Dzikir',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dhikrItemId,
                          isExpanded: true,
                          items: items
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.text),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final item = items.firstWhere((d) => d.id == value);
                            setState(() {
                              _dhikrItemId = value;
                              if (!_isEditing) {
                                _targetController.text =
                                    item.targetCount.toString();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(context),
                            borderRadius: BorderRadius.circular(4),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Jam',
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatTimeOfDay(_time)),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _targetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target hitungan',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hari aktif',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _DaySelector(
                      selectedDays: _selectedDays,
                      onChanged: (day) {
                        setState(() {
                          if (_selectedDays.contains(day)) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                          if (_selectedDays.isEmpty) {
                            _selectedDays.add(day);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submit(
                                  context,
                                  collectionId: selectedCollection.id,
                                  dhikrItem: dhikrItem,
                                ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Todo'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorNotice(
                message: 'Gagal memuat dzikir: $error',
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorNotice(
            message: 'Gagal memuat koleksi: $error',
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() => _time = newTime);
    }
  }

  Future<void> _submit(
    BuildContext context, {
    required String collectionId,
    required DhikrItem dhikrItem,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final target = int.tryParse(_targetController.text);
    if (target == null || target <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Target harus lebih dari 0')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu hari')),
      );
      return;
    }

    try {
      if (_isEditing) {
        final todo = widget.initialTodo;
        if (todo == null) return;
        await updateDzikirTodoAction(
          ref,
          goalSessionId: todo.goalSessionId,
          sessionTime: _formatTimeForDb(_time),
          targetCount: target,
          daysOfWeek: List<int>.from(_selectedDays),
          name: dhikrItem.text,
          collectionId: collectionId,
          dhikrItemId: dhikrItem.id,
        );
      } else {
        await createDzikirTodoAction(
          ref,
          collectionId: collectionId,
          dhikrItemId: dhikrItem.id,
          sessionTime: _formatTimeForDb(_time),
          targetCount: target,
          daysOfWeek: List<int>.from(_selectedDays),
          name: dhikrItem.text,
        );
      }

      if (!mounted) return;
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan todo: $error')),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeForDb(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TasbihCollection _resolveSelectedCollection(
    List<TasbihCollection> collections,
  ) {
    final fallback = collections.first;
    final currentId = _collectionId;
    if (currentId == null) {
      _collectionId = fallback.id;
      return fallback;
    }
    final match = collections.firstWhere(
      (c) => c.id == currentId,
      orElse: () => fallback,
    );
    _collectionId = match.id;
    return match;
  }

  DhikrItem _resolveSelectedDhikr(List<DhikrItem> items) {
    final fallback = items.first;
    final currentId = _dhikrItemId;
    if (currentId == null) {
      _dhikrItemId = fallback.id;
      return fallback;
    }
    final match = items.firstWhere(
      (d) => d.id == currentId,
      orElse: () => fallback,
    );
    _dhikrItemId = match.id;
    return match;
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.selectedDays, required this.onChanged});

  final List<int> selectedDays;
  final ValueChanged<int> onChanged;

  static const _days = [
    {'label': 'Sen', 'value': 1},
    {'label': 'Sel', 'value': 2},
    {'label': 'Rab', 'value': 3},
    {'label': 'Kam', 'value': 4},
    {'label': 'Jum', 'value': 5},
    {'label': 'Sab', 'value': 6},
    {'label': 'Min', 'value': 7},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      children: _days.map((day) {
        final value = day['value']! as int;
        final label = day['label']! as String;
        final selected = selectedDays.contains(value);
        return FilterChip(
          label: Text(label),
          selected: selected,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          onSelected: (_) => onChanged(value),
        );
      }).toList(),
    );
  }
}

class _EmptyCollectionsNotice extends StatelessWidget {
  const _EmptyCollectionsNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.collections_bookmark, size: 56),
        const SizedBox(height: 12),
        Text(
          'Belum ada koleksi tasbih',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Buat koleksi terlebih dahulu di tab Tasbih untuk memilih dzikir.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CollectionWithoutDhikr extends StatelessWidget {
  const _CollectionWithoutDhikr({required this.collection});

  final TasbihCollection collection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.format_list_bulleted, size: 56),
        const SizedBox(height: 12),
        Text(
          'Koleksi "${collection.name}" belum memiliki dzikir.',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tambahkan dzikir ke koleksi tersebut terlebih dahulu.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

String _formatSessionTime(String? value) {
  if (value == null || value.isEmpty) return '--:--';
  final parts = value.split(':');
  if (parts.length < 2) return value;
  final hour = parts[0].padLeft(2, '0');
  final minute = parts[1].padLeft(2, '0');
  return '$hour:$minute';
}

class _LoginRequiredState extends StatelessWidget {
  const _LoginRequiredState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dzikir Planner')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text(
                'Silakan masuk terlebih dahulu',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Masuk melalui tab Profil kemudian kembali ke sini untuk melihat Dzikir Planner.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
