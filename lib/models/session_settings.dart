/// Holds the learner's current session configuration.
/// This is intentionally simple in Prompt 1's build — the full
/// Learner Profile Engine (level tracking, recurring mistakes, etc.)
/// gets its own model in later prompts (Prompt 3 / 22 / 23).
class SessionSettings {
  String mode; // friend | tutor | coach
  String correctionMode; // conversation_only | smart | strict
  String estimatedLevel; // A0..C2 or "unknown"
  String accent; // indian | american | british

  /// Set by the Personalized Learning Engine (Prompt 3) when the learner
  /// starts a specific generated session — e.g. "Roleplay: workplace small
  /// talk, practicing follow-up questions." Null during free conversation.
  String? sessionFocus;

  SessionSettings({
    this.mode = 'friend',
    this.correctionMode = 'smart',
    this.estimatedLevel = 'unknown',
    this.accent = 'indian',
    this.sessionFocus,
  });

  SessionSettings copyWith({
    String? mode,
    String? correctionMode,
    String? estimatedLevel,
    String? accent,
    String? sessionFocus,
  }) {
    return SessionSettings(
      mode: mode ?? this.mode,
      correctionMode: correctionMode ?? this.correctionMode,
      estimatedLevel: estimatedLevel ?? this.estimatedLevel,
      accent: accent ?? this.accent,
      sessionFocus: sessionFocus ?? this.sessionFocus,
    );
  }
}
