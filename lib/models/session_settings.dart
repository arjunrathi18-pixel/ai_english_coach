import 'ai_personality.dart';
import 'conversation_length.dart';
import 'correction_intensity.dart';

/// Holds the learner's current session configuration.
class SessionSettings {
  String mode; // friend | tutor | coach
  CorrectionIntensity correctionIntensity; // Prompt 5: light | balanced | detailed | strict
  String estimatedLevel; // A0..C2 or "unknown"
  String accent; // indian | american | british

  /// Set by the Personalized Learning Engine (Prompt 3) when the learner
  /// starts a specific generated session — e.g. "Roleplay: workplace small
  /// talk, practicing follow-up questions." Null during free conversation.
  String? sessionFocus;

  /// Friend Mode personality (Prompt 4, section 18) — tone/energy only,
  /// never difficulty.
  AiPersonality personality;

  /// Target conversation pacing (Prompt 4, section 11).
  ConversationLength conversationLength;

  SessionSettings({
    this.mode = 'friend',
    this.correctionIntensity = CorrectionIntensity.balanced,
    this.estimatedLevel = 'unknown',
    this.accent = 'indian',
    this.sessionFocus,
    this.personality = AiPersonality.friendly,
    this.conversationLength = ConversationLength.normal,
  });

  SessionSettings copyWith({
    String? mode,
    CorrectionIntensity? correctionIntensity,
    String? estimatedLevel,
    String? accent,
    String? sessionFocus,
    AiPersonality? personality,
    ConversationLength? conversationLength,
  }) {
    return SessionSettings(
      mode: mode ?? this.mode,
      correctionIntensity: correctionIntensity ?? this.correctionIntensity,
      estimatedLevel: estimatedLevel ?? this.estimatedLevel,
      accent: accent ?? this.accent,
      sessionFocus: sessionFocus ?? this.sessionFocus,
      personality: personality ?? this.personality,
      conversationLength: conversationLength ?? this.conversationLength,
    );
  }
}
