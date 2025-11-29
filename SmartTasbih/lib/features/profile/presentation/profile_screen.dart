import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../domain/achievement_overview.dart';
import '../domain/dhikr_usage_stat.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileFutureProvider);
    final badges = ref.watch(badgeListProvider);
    final achievementOverview = ref.watch(achievementOverviewProvider);
    final topDhikrUsage = ref.watch(topDhikrUsageProvider);

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
                  'Dzikir Terbanyak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                AsyncValueWidget(
                  value: topDhikrUsage,
                  builder: (stats) {
                    if (stats.isEmpty) {
                      return const _EmptyDhikrUsageState();
                    }
                    final maxVisible = stats.length < 5 ? stats.length : 5;
                    final listHeight = (maxVisible * 110).toDouble();
                    return Scrollbar(
                      thumbVisibility: stats.length > maxVisible,
                      child: SizedBox(
                        height: listHeight,
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: stats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final stat = stats[index];
                            return _DhikrUsageTile(
                              stat: stat,
                              rank: index + 1,
                            );
                          },
                        ),
                      ),
                    );
                  },
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
  ref.invalidate(topDhikrUsageProvider);

  await Future.wait([
    ref.refresh(profileFutureProvider.future),
    ref.refresh(badgeListProvider.future),
    ref.refresh(achievementOverviewProvider.future),
    ref.refresh(topDhikrUsageProvider.future),
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
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada aktivitas minggu ini',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Mulai dzikir untuk melihat progres Anda',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get last 7 days data
    final lastSevenDays = _getLastSevenDaysData(trend);
    final totalCount = lastSevenDays.fold<int>(0, (sum, day) => sum + day['count'] as int);
    final averageCount = (totalCount / 7).round();
    final maxValue = lastSevenDays.fold<int>(0, (max, day) => (day['count'] as int) > max ? day['count'] as int : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary statistics
        Row(
          children: [
            Expanded(
              child: _StatSummary(
                title: 'Total',
                value: totalCount.toString(),
                icon: Icons.summarize,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatSummary(
                title: 'Rata-rata',
                value: '$averageCount/hari',
                icon: Icons.calculate,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatSummary(
                title: 'Tertinggi',
                value: '$maxValue',
                icon: Icons.trending_up,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main chart
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: lastSevenDays.map((dayData) {
              final count = dayData['count'] as int;
              final dayName = dayData['day'] as String;
              final isToday = dayData['isToday'] as bool;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value label on top of bar
                      Text(
                        count.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Column bar
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(alpha: 0.7),
                                isToday
                                    ? theme.colorScheme.primary.withValues(alpha: 0.8)
                                    : theme.colorScheme.primary.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Fill animation effect
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),

                              // Today indicator
                              if (isToday)
                                Positioned(
                                  top: 4,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Day label
                      Text(
                        dayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                          color: isToday
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Today indicator
                      if (isToday)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Insight message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getInsightMessage(lastSevenDays, averageCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getLastSevenDaysData(List<MapEntry<String, int>> trend) {
    final now = DateTime.now();
    final lastSevenDays = <Map<String, dynamic>>[];

    // Get last 7 days including today
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final dayName = _dayAbbreviations[date.weekday] ?? dateStr.substring(8);

      // Find count for this date in trend data
      final dayCount = trend.firstWhere(
        (entry) => entry.key == dateStr,
        orElse: () => MapEntry(dateStr, 0),
      ).value;

      final isToday = i == 0;

      lastSevenDays.add({
        'date': dateStr,
        'day': isToday ? 'Hari Ini' : dayName,
        'count': dayCount,
        'isToday': isToday,
      });
    }

    return lastSevenDays;
  }

  String _getInsightMessage(List<Map<String, dynamic>> lastSevenDays, int averageCount) {
    final today = lastSevenDays.last['count'] as int;
    final yesterday = lastSevenDays.length > 1 ? lastSevenDays[lastSevenDays.length - 2]['count'] as int : 0;

    if (today > yesterday) {
      if (today > averageCount) {
        return 'Hebat! Hari ini Anda lebih aktif dari biasanya. Tetap konsisten! 🎉';
      } else {
        return 'Bagus! Aktivitas hari ini meningkat dari kemarin. Keep it up! 💪';
      }
    } else if (today < yesterday) {
      return 'Jangan menyerah! Setiap hari adalah kesempatan baru untuk istiqamah. 🌟';
    } else {
      if (today == 0) {
        return 'Mulai hari ini dengan dzikir, niscaya akan membawa keberkahan. 🙏';
      } else {
        return 'Konsistensi adalah kunci! Teruskan dzikir Anda. ✨';
      }
    }
  }
}

class _StatSummary extends StatelessWidget {
  const _StatSummary({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DhikrUsageTile extends StatelessWidget {
  const _DhikrUsageTile({required this.stat, required this.rank});

  final DhikrUsageStat stat;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.decimalPattern();
    final subtitle = stat.translation?.isNotEmpty == true
        ? stat.translation!
        : stat.collectionName ?? 'Tanpa koleksi';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatLastUsed(stat.lastUsedDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(stat.totalCount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'bacaan',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastUsed(DateTime? date) {
    if (date == null) return 'Belum ada aktivitas';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Dibaca hari ini';
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Terakhir kemarin';
    }
    return 'Terakhir ${DateFormat('dd MMM yyyy').format(date)}';
  }
}

class _EmptyDhikrUsageState extends StatelessWidget {
  const _EmptyDhikrUsageState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, size: 48),
          const SizedBox(height: 12),
          Text(
            'Belum ada data dzikir',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai dzikir menggunakan tasbih untuk melihat dzikir terfavoritmu.',
            textAlign: TextAlign.center,
          ),
        ],
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
