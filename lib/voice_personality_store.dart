import 'package:shared_preferences/shared_preferences.dart';
import 'ai_personality.dart';
import 'conversation_length.dart';
import 'correction_intensity.dart';
import 'session_settings.dart';

/// Saves the learner's chosen DEFAULTS across app launches (Prompt 19,
/// sections 12, 104). Previously these only lived inside each chat
/// session's in-memory SessionSettings and reset every time.
class VoicePersonalityStore {
  static const _personalityKey = 'default_personality_v1';
  static const _accentKey = 'default_accent_v1';
  static const _correctionKey = 'default_correction_v1';
  static const _lengthKey = 'default_length_v1';

  static Future<void> save({
    required AiPersonality personality,
    required String accent,
    required CorrectionIntensity correctionIntensity,
    required ConversationLength conversationLength,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalityKey, personality.key);
    await prefs.setString(_accentKey, accent);
    await prefs.setString(_correctionKey, correctionIntensity.key);
    await prefs.setString(_lengthKey, conversationLength.key);
  }

  /// Returns a SessionSettings seeded with the saved defaults (falls back
  /// to the built-in defaults for anything never saved).
  static Future<SessionSettings> loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(_personalityKey);
    final a = prefs.getString(_accentKey);
    final c = prefs.getString(_correctionKey);
    final l = prefs.getString(_lengthKey);

    return SessionSettings(
      personality: p != null ? AiPersonalityLabel.fromKey(p) : AiPersonality.friendly,
      accent: a ?? 'indian',
      correctionIntensity:
          c != null ? CorrectionIntensityLabel.fromKey(c) : CorrectionIntensity.balanced,
      conversationLength:
          l != null ? ConversationLengthLabel.fromKey(l) : ConversationLength.normal,
    );
  }
}
