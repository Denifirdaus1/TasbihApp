import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/arabic_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../prayer_circles/presentation/prayer_circle_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../recommendations/data/ayah_provider.dart';
import '../../recommendations/presentation/mood_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _lottieUrls = [
    'https://assets9.lottiefiles.com/packages/lf20_jcikwtux.json',
    'https://assets6.lottiefiles.com/packages/lf20_nysiytpa.json',
    'https://assets4.lottiefiles.com/packages/lf20_jcikwtux.json',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileFutureProvider);
    final circles = ref.watch(prayerCirclesProvider);
    final ayah = ref.watch(ayahOfTheDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartTasbih'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileFutureProvider);
          ref.invalidate(prayerCirclesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AsyncValueWidget(
              value: profile,
              builder: (data) => _ProfileHeader(
                level: data.currentTreeLevel,
                points: data.totalPoints,
                username: data.username ?? 'Pengguna',
              ),
            ),
            const SizedBox(height: 24),
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
                          'Mood Tracker',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () async {
                            await NotificationService.scheduleDailyReminder(
                              time: const TimeOfDay(hour: 5, minute: 0),
                              message:
                                  'Mari mulai hari dengan dzikir favoritmu hari ini.',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pengingat harian aktif pukul 05:00'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications),
                          tooltip: 'Atur pengingat SmartTasbih',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const MoodSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _AyahCard(ayah: ayah),
            const SizedBox(height: 24),
            Text(
              'Lingkaran Aktif',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: circles,
              builder: (items) {
                if (items.isEmpty) {
                  return const Text(
                      'Belum ada circle. Buka tab Lingkaran untuk membuatnya.');
                }
                final circle = items.first;
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(circle.name),
                  subtitle: Text('Kode: ${circle.inviteCode}'),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.level,
    required this.points,
    required this.username,
  });

  final int level;
  final int points;
  final String username;

  @override
  Widget build(BuildContext context) {
    final lottieUrl =
        DashboardScreen._lottieUrls[level % DashboardScreen._lottieUrls.length];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: Lottie.network(lottieUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Level Pohon: $level'),
                  Text('Total Poin: $points'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.ayah});

  final DailyAyah ayah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ayat Hari Ini',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ArabicText(
              ayah.arabic,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ayah.translation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'QS ${ayah.surahLatinName} (${ayah.surahArabicName})',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'Ayat ${ayah.verseNumber}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
