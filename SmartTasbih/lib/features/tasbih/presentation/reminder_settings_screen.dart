import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../domain/tasbih_collection.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key, required this.collection});

  final TasbihCollection collection;

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 0);
  final _messageController = TextEditingController();
  final List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _messageController.text =
        'Waktunya dzikir ${widget.collection.name}! Jangan lupa untuk berdzikir hari ini.';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Pengingat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getColor(
                            widget.collection.color,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(widget.collection.icon),
                          color: _getColor(widget.collection.color),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.collection.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.collection.description != null)
                              Text(
                                widget.collection.description!,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Aktifkan Pengingat'),
            subtitle: const Text('Dapatkan notifikasi untuk dzikir ini'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_isEnabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Pengingat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Atur Waktu'),
                      subtitle: Text(
                        _selectedTime.format(context),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hari Pengingat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DayChip(
                          label: 'Sen',
                          value: 1,
                          isSelected: _selectedDays.contains(1),
                          onTap: () => _toggleDay(1),
                        ),
                        _DayChip(
                          label: 'Sel',
                          value: 2,
                          isSelected: _selectedDays.contains(2),
                          onTap: () => _toggleDay(2),
                        ),
                        _DayChip(
                          label: 'Rab',
                          value: 3,
                          isSelected: _selectedDays.contains(3),
                          onTap: () => _toggleDay(3),
                        ),
                        _DayChip(
                          label: 'Kam',
                          value: 4,
                          isSelected: _selectedDays.contains(4),
                          onTap: () => _toggleDay(4),
                        ),
                        _DayChip(
                          label: 'Jum',
                          value: 5,
                          isSelected: _selectedDays.contains(5),
                          onTap: () => _toggleDay(5),
                        ),
                        _DayChip(
                          label: 'Sab',
                          value: 6,
                          isSelected: _selectedDays.contains(6),
                          onTap: () => _toggleDay(6),
                        ),
                        _DayChip(
                          label: 'Min',
                          value: 7,
                          isSelected: _selectedDays.contains(7),
                          onTap: () => _toggleDay(7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesan Pengingat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan pesan pengingat...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_isEnabled)
            FilledButton.icon(
              onPressed: _saveReminder,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Pengingat'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tutup'),
            ),
        ],
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
  }

  Future<void> _saveReminder() async {
    try {
      // Request exact alarm permission first (Android 12+)
      final hasPermission =
          await NotificationService.requestExactAlarmPermission();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission "Alarms & reminders" diperlukan untuk pengingat tepat waktu. Silakan aktifkan di Settings.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Schedule notification
      await NotificationService.scheduleCollectionReminder(
        collectionId: widget.collection.id,
        collectionName: widget.collection.name,
        time: _selectedTime,
        message: _messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
