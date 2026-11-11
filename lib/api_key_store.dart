import 'package:shared_preferences/shared_preferences.dart';

/// Keys for every supported AI service, stored only on this device.
/// The app can hold several at once and fails over between them.
class ApiKeyStore {
  static const List<String> providerIds = ['groq', 'cerebras', 'gemini', 'openrouter', 'anthropic'];

  // An Anthropic key may still be baked into old builds via --dart-define.
  static const String _buildAnthropicKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
  static const String _legacyAnthropicPref = 'user_anthropic_api_key_v1';

  static String _pref(String id) => 'api_key_${id}_v2';

  static Future<String> get(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_pref(id)) ?? '').trim();
    if (saved.isNotEmpty) return saved;
    if (id == 'anthropic') {
      final legacy = (prefs.getString(_legacyAnthropicPref) ?? '').trim();
      if (legacy.isNotEmpty) return legacy;
      return _buildAnthropicKey.trim();
    }
    return '';
  }

  static Future<void> save(String id, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pref(id), key.trim());
  }

  static Future<void> clear(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pref(id));
    if (id == 'anthropic') await prefs.remove(_legacyAnthropicPref);
  }

  /// Ids of every service that currently has a key.
  static Future<List<String>> connected() async {
    final out = <String>[];
    for (final id in providerIds) {
      if ((await get(id)).isNotEmpty) out.add(id);
    }
    return out;
  }

  static Future<bool> hasKey() async => (await connected()).isNotEmpty;
}
