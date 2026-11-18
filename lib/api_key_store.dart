import 'package:shared_preferences/shared_preferences.dart';

/// Device-only settings for the AI providers. Keys never leave this phone
/// and are never written to the repository, the APK, or logs.
class ApiKeyStore {
  static const List<String> providerIds = ['groq', 'cerebras', 'gemini', 'openrouter', 'anthropic'];
  static const Set<String> paidIds = {'anthropic'};
  static const List<String> defaultPriority = ['groq', 'cerebras', 'gemini', 'openrouter', 'anthropic'];

  // Optional paid key may still come from an old build (--dart-define).
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

  // ── Zero-cost-only mode (DEFAULT ON). While ON, paid providers are blocked.
  static Future<bool> zeroCostOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('zero_cost_only_v1') ?? true;
  }

  static Future<void> setZeroCostOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zero_cost_only_v1', value);
  }

  // ── Per-provider on/off (default on)
  static Future<bool> isEnabled(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ai_enabled_${id}_v1') ?? true;
  }

  static Future<void> setEnabled(String id, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_enabled_${id}_v1', value);
  }

  // ── Configurable priority (paid providers are always tried after free ones)
  static Future<List<String>> priority() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getStringList('ai_priority_v1') ?? []).where(providerIds.contains).toList();
    final out = <String>[...saved];
    for (final id in defaultPriority) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }

  static Future<void> setPriority(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ai_priority_v1', order);
  }

  // ── Models the user verified as free on the provider's own site.
  static Future<Set<String>> userVerifiedModels() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('ai_user_models_v1') ?? []).toSet();
  }

  static Future<void> addUserModel(String provider, String model) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList('ai_user_models_v1') ?? []).toSet()..add('$provider:${model.trim()}');
    await prefs.setStringList('ai_user_models_v1', set.toList());
  }

  static Future<void> removeUserModel(String entry) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList('ai_user_models_v1') ?? []).toSet()..remove(entry);
    await prefs.setStringList('ai_user_models_v1', set.toList());
  }

  /// IDs that have a saved key.
  static Future<List<String>> connected() async {
    final out = <String>[];
    for (final id in providerIds) {
      if ((await get(id)).isNotEmpty) out.add(id);
    }
    return out;
  }

  /// True when at least one USABLE provider has a key (paid ones count only
  /// when zero-cost-only mode is OFF).
  static Future<bool> hasKey() async {
    final zero = await zeroCostOnly();
    for (final id in await connected()) {
      if (paidIds.contains(id) && zero) continue;
      if (!await isEnabled(id)) continue;
      return true;
    }
    return false;
  }
}
