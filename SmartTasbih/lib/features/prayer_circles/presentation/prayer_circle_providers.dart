import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../data/prayer_circle_repository.dart';
import '../domain/prayer_circle_models.dart';

final prayerCircleRepositoryProvider = Provider<PrayerCircleRepository>(
  (ref) => PrayerCircleRepository(ref.watch(supabaseClientProvider)),
);

final prayerCirclesProvider = FutureProvider<List<PrayerCircle>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(prayerCircleRepositoryProvider).fetchCircles(user.id);
});

final circleGoalsStreamProvider =
    StreamProvider.family<List<CircleGoal>, int>((ref, circleId) {
  return ref.watch(prayerCircleRepositoryProvider).goalsStream(circleId);
});
