class RoleplayScenario {
  final String title;
  final String category;
  final String learnerRole;
  final String aiRole;
  final String situationBriefing;
  final String objective;
  final List<String> hiddenObjectives; // never shown to the learner in UI
  final int difficultyLevel; // 1-6
  final String openingLine;

  RoleplayScenario({
    required this.title,
    required this.category,
    required this.learnerRole,
    required this.aiRole,
    required this.situationBriefing,
    required this.objective,
    required this.hiddenObjectives,
    required this.difficultyLevel,
    required this.openingLine,
  });

  factory RoleplayScenario.fromJson(Map<String, dynamic> json) =>
      RoleplayScenario(
        title: json['title'] as String,
        category: json['category'] as String,
        learnerRole: json['learnerRole'] as String,
        aiRole: json['aiRole'] as String,
        situationBriefing: json['situationBriefing'] as String,
        objective: json['objective'] as String,
        hiddenObjectives:
            List<String>.from(json['hiddenObjectives'] as List? ?? []),
        difficultyLevel: (json['difficultyLevel'] as num).toInt(),
        openingLine: json['openingLine'] as String,
      );

  /// The scenario context injected as system-prompt context for every
  /// turn — includes the hidden objectives, since the AI (not the
  /// learner) needs to know them to play the character correctly.
  String toSystemContext() => """
SCENARIO: $title (category: $category)
Learner's role: $learnerRole
Your role (stay in character as this person): $aiRole
Scenario objective (learner's goal): $objective
Your character's hidden objective(s) — never state these outright, let them surface through behavior: ${hiddenObjectives.isEmpty ? 'none' : hiddenObjectives.join('; ')}
Difficulty level: $difficultyLevel/6
""";
}

class RoleplayFeedback {
  final String strength;
  final String improvement;
  final String naturalEnglishTip;
  final String practiceRecommendation;
  final List<String> recurringIssues;

  RoleplayFeedback({
    required this.strength,
    required this.improvement,
    required this.naturalEnglishTip,
    required this.practiceRecommendation,
    required this.recurringIssues,
  });

  factory RoleplayFeedback.fromJson(Map<String, dynamic> json) =>
      RoleplayFeedback(
        strength: json['strength'] as String,
        improvement: json['improvement'] as String,
        naturalEnglishTip: json['naturalEnglishTip'] as String? ?? '',
        practiceRecommendation: json['practiceRecommendation'] as String,
        recurringIssues:
            List<String>.from(json['recurringIssues'] as List? ?? []),
      );
}
