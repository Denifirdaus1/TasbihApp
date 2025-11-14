import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../tasbih/presentation/tasbih_providers.dart';
import '../data/profile_repository.dart';
import '../domain/achievement_overview.dart';
import '../domain/profile.dart';
import '../domain/user_badge.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final profileFutureProvider = FutureProvider<Profile>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Belum ada user yang login.');
  }
  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});

final badgeListProvider = FutureProvider<List<UserBadge>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return [];
  }
  return ref.watch(profileRepositoryProvider).fetchBadges(user.id);
});

final achievementOverviewProvider = FutureProvider<AchievementOverview>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Belum ada user yang login.');
  }

  final tasbihRepository = ref.watch(tasbihRepositoryProvider);
  final stats = await tasbihRepository.getStatistics(user.id);
  final collections = await tasbihRepository.fetchCollections(user.id);

  final dailyStatsRaw = (stats['dailyStats'] as Map?) ?? <String, dynamic>{};
  final dailyStats = dailyStatsRaw.map<String, int>(
    (key, value) => MapEntry(key.toString(), (value as num).toInt()),
  );

  return AchievementOverview(
    totalClicks: (stats['totalCount'] as num?)?.toInt() ?? 0,
    totalCollections: collections.length,
    completedSessions: (stats['completedCount'] as num?)?.toInt() ?? 0,
    dailyStats: dailyStats,
  );
});
