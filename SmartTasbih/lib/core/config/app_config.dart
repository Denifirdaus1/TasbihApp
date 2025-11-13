class AppConfig {
  static const String supabaseUrl = 'https://yzjddizaqsikctelciby.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6amRkaXphcXNpa2N0ZWxjaWJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NTc5MzQsImV4cCI6MjA3ODQzMzkzNH0.72WoH2Tm4wFOwmRCSUNbglcsIhjU9uy71z1EHZ7jfB4';

  /// Digunakan Supabase untuk redirect callback Google OAuth.
  static const String oauthRedirectUri =
      'com.smarttasbih.app://login-callback';

  static const int smartReminderNotificationId = 7001;
}
