import 'package:shared_preferences/shared_preferences.dart';

/// The Anthropic API key can come from two places:
///  1. the key the learner pastes in the app (Profile > AI Connection),
///     stored only on this device, or
///  2. the key baked in at build time via --dart-define (GitHub secret).
/// The in-app key wins, so the app can be fixed without rebuilding.
class ApiKeyStore {
  static const _key = 'user_anthropic_api_key_v1';
  static const String _buildKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_key) ?? '').trim();
    return saved.isNotEmpty ? saved : _buildKey.trim();
  }

  static Future<bool> hasKey() async => (await get()).isNotEmpty;

  static bool get hasBuildKey => _buildKey.trim().isNotEmpty;

  static Future<bool> hasSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_key) ?? '').trim().isNotEmpty;
  }

  static Future<void> save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
