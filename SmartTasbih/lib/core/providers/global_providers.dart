import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final sessionStreamProvider = StreamProvider<Session?>(
  (ref) => ref.watch(authRepositoryProvider).sessionStream,
);

final currentSessionProvider = Provider<Session?>((ref) {
  final asyncSession = ref.watch(sessionStreamProvider);
  return asyncSession.whenOrNull(
        data: (data) => data,
      ) ??
      ref.watch(authRepositoryProvider).currentSession;
});

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(currentSessionProvider)?.user,
);
