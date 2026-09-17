/// Selectable conversational personality (Prompt 4, section 18).
/// This affects tone/energy/vocabulary style only — never the English
/// difficulty level, which is driven by the learner's estimated level.
enum AiPersonality {
  friendly,
  calm,
  funny,
  professional,
  energetic,
  curious,
  motivational,
  intellectual,
  strict,
  casual,
}

extension AiPersonalityLabel on AiPersonality {
  String get label {
    switch (this) {
      case AiPersonality.friendly:
        return 'Friendly';
      case AiPersonality.calm:
        return 'Calm';
      case AiPersonality.funny:
        return 'Funny';
      case AiPersonality.professional:
        return 'Professional';
      case AiPersonality.energetic:
        return 'Energetic';
      case AiPersonality.curious:
        return 'Curious';
      case AiPersonality.motivational:
        return 'Motivational';
      case AiPersonality.intellectual:
        return 'Intellectual';
      case AiPersonality.strict:
        return 'Strict';
      case AiPersonality.casual:
        return 'Casual';
    }
  }

  String get key => toString().split('.').last;

  static AiPersonality fromKey(String key) {
    return AiPersonality.values.firstWhere(
      (p) => p.key == key,
      orElse: () => AiPersonality.friendly,
    );
  }
}
