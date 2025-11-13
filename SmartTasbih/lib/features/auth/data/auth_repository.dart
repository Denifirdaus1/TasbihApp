import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<Session?> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => event.session);

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => currentSession?.user;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUri,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
