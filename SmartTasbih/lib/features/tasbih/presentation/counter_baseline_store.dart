import 'package:shared_preferences/shared_preferences.dart';

/// Handles persisting local reset baselines so counter resets don't erase
/// historical click data.
class CounterBaselineStore {
  CounterBaselineStore._();

  static const _keyPrefix = 'tasbih_counter_baseline_';

  static String _buildKey(String sessionId) => '$_keyPrefix$sessionId';

  /// Returns the saved baseline for a given session or 0 if none exists.
  static Future<int> readBaseline(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_buildKey(sessionId)) ?? 0;
  }

  /// Persists the latest baseline. Removes the key when baseline is 0 to keep
  /// storage tidy.
  static Future<void> saveBaseline(String sessionId, int baseline) async {
    final prefs = await SharedPreferences.getInstance();
    if (baseline <= 0) {
      await prefs.remove(_buildKey(sessionId));
      return;
    }
    await prefs.setInt(_buildKey(sessionId), baseline);
  }

  static Future<void> clearBaseline(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_buildKey(sessionId));
  }
}
