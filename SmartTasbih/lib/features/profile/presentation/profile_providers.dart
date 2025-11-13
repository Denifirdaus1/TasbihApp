import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../data/profile_repository.dart';
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
