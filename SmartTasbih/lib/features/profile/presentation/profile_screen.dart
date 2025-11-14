import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../domain/achievement_overview.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileFutureProvider);
    final badges = ref.watch(badgeListProvider);
    final achievementOverview = ref.watch(achievementOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: profile,
        builder: (data) {
          return RefreshIndicator(
            onRefresh: () => _refreshDashboard(ref),
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: data.avatarUrl != null
                              ? NetworkImage(data.avatarUrlWithCache)
                              : null,
                          child: data.avatarUrl == null
                              ? Text(data.username?.substring(0, 1) ?? '?')
                              : null,
                        ),
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: IconButton(
                            onPressed: () =>
                                _showImageSourceDialog(context, ref, data.id),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data.username ?? 'Tanpa Nama',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showEditNameDialog(
                                  context,
                                  ref,
                                  data.id,
                                  data.username,
                                ),
                                icon: const Icon(Icons.edit, size: 18),
                              ),
                            ],
                          ),
                          Text('Pohon level ${data.currentTreeLevel}'),
                          Text('${data.totalPoints} poin'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Dashboard Pencapaian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                AsyncValueWidget(
                  value: achievementOverview,
                  builder: (stats) => _AchievementDashboard(
                    stats: stats,
                    totalPoints: data.totalPoints,
                    unlockedBadges:
                        badges.whenOrNull(data: (items) => items.length) ?? 0,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Badge',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                AsyncValueWidget(
                  value: badges,
                  builder: (items) {
                    if (items.isEmpty) {
                      return const Text('Belum ada badge.');
                    }
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: items
                          .map(
                            (badge) => Chip(
                              avatar: const Icon(Icons.emoji_events, size: 18),
                              label: Text(badge.badgeName),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String? currentName,
  ) {
    final controller = TextEditingController(text: currentName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama',
            hintText: 'Masukkan nama baru',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                try {
                  await ref
                      .read(profileRepositoryProvider)
                      .updateUsername(userId, newName);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ref.invalidate(profileFutureProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama berhasil diperbarui')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui nama: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Foto Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, context, ref, userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, context, ref, userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Mengunggah foto...'),
                ],
              ),
            ),
          );
        }

        try {
          final avatarUrl = await ref
              .read(profileRepositoryProvider)
              .uploadProfileImage(userId, pickedFile.path);
          await ref
              .read(profileRepositoryProvider)
              .updateAvatarUrl(userId, avatarUrl);

          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading dialog
          }

          // Add small delay to ensure database is updated
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(profileFutureProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto profil berhasil diperbarui')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunggah foto: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $e')));
      }
    }
  }
}

Future<void> _refreshDashboard(WidgetRef ref) async {
  ref.invalidate(profileFutureProvider);
  ref.invalidate(badgeListProvider);
  ref.invalidate(achievementOverviewProvider);

  await Future.wait([
    ref.refresh(profileFutureProvider.future),
    ref.refresh(badgeListProvider.future),
    ref.refresh(achievementOverviewProvider.future),
  ]);
}

class _AchievementDashboard extends StatelessWidget {
  const _AchievementDashboard({
    required this.stats,
    required this.totalPoints,
    required this.unlockedBadges,
  });

  final AchievementOverview stats;
  final int totalPoints;
  final int unlockedBadges;

  static const _badgeGoals = [
    _BadgeGoal(
      title: 'Pemula',
      description: 'Capai 1.000 ketukan tasbih',
      target: 1000,
      icon: Icons.looks_one,
    ),
    _BadgeGoal(
      title: 'Istiqamah',
      description: 'Capai 5.000 ketukan tasbih',
      target: 5000,
      icon: Icons.looks_two,
    ),
    _BadgeGoal(
      title: 'Master Tasbih',
      description: 'Capai 15.000 ketukan tasbih',
      target: 15000,
      icon: Icons.looks_3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            _StatCard(
              title: 'Total Klik',
              value: _formatNumber(stats.totalClicks),
              subtitle: 'Keseluruhan tasbih',
              icon: Icons.fingerprint,
              color: theme.colorScheme.primary,
            ),
            _StatCard(
              title: 'Koleksi Aktif',
              value: stats.totalCollections.toString(),
              subtitle: 'Koleksi Anda',
              icon: Icons.folder_shared,
              color: theme.colorScheme.secondary,
            ),
            _StatCard(
              title: 'Rata-rata/ Hari',
              value: stats.averageDailyCount.toStringAsFixed(0),
              subtitle: 'Selama periode berjalan',
              icon: Icons.today,
              color: theme.colorScheme.tertiary,
            ),
            _StatCard(
              title: 'Progress Target',
              value: '${(stats.completionRate * 100).round()}%',
              subtitle: 'Sesi tuntas',
              icon: Icons.flag_circle,
              color: theme.colorScheme.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivitas 7 Hari Terakhir',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _DailyTrend(trend: stats.lastSevenDaysTrend),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress Badge',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$unlockedBadges badge diperoleh',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._badgeGoals.map((goal) {
                  final progress = (stats.totalClicks / goal.target)
                      .clamp(0, 1)
                      .toDouble();
                  final percent = (progress * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              goal.icon,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    goal.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text('$percent%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatNumber(stats.totalClicks)} / ${_formatNumber(goal.target)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(height: 24, color: theme.dividerColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Poin', style: theme.textTheme.titleSmall),
                    Text(
                      _formatNumber(totalPoints),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(num value) {
    final formatter = NumberFormat.compact(locale: 'id_ID');
    return formatter.format(value);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTrend extends StatelessWidget {
  const _DailyTrend({required this.trend});

  final List<MapEntry<String, int>> trend;
  static const _dayAbbreviations = <int, String>{
    DateTime.monday: 'Sen',
    DateTime.tuesday: 'Sel',
    DateTime.wednesday: 'Rab',
    DateTime.thursday: 'Kam',
    DateTime.friday: 'Jum',
    DateTime.saturday: 'Sab',
    DateTime.sunday: 'Min',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (trend.isEmpty) {
      return Text(
        'Belum ada aktivitas minggu ini.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final maxValue = trend.fold<int>(0, (previousValue, element) {
      if (element.value > previousValue) {
        return element.value;
      }
      return previousValue;
    });

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((entry) {
          final date = DateTime.tryParse(entry.key);
          final label = date != null
              ? (_dayAbbreviations[date.weekday] ?? entry.key)
              : entry.key;
          final heightFactor = maxValue == 0 ? 0.0 : (entry.value / maxValue);
          final barHeight = (heightFactor * 100) + 16;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      entry.value.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BadgeGoal {
  const _BadgeGoal({
    required this.title,
    required this.description,
    required this.target,
    required this.icon,
  });

  final String title;
  final String description;
  final int target;
  final IconData icon;
}
