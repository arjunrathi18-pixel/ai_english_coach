/// One phase of a session structure (Prompt 3, section 8): e.g. WARM-UP,
/// TEACH, PRACTICE, CONVERSATION, CHALLENGE, CORRECTION, REVIEW.
class SessionPhase {
  final String phase;
  final String description;
  final int minutes;

  SessionPhase({
    required this.phase,
    required this.description,
    required this.minutes,
  });

  factory SessionPhase.fromJson(Map<String, dynamic> json) => SessionPhase(
        phase: json['phase'] as String,
        description: json['description'] as String,
        minutes: (json['minutes'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'description': description,
        'minutes': minutes,
      };
}

/// A single personalized lesson generated for "today" (Prompt 3,
/// sections 7, 17, 36). This is what actually drives the live
/// conversation in ChatScreen once the learner taps "Start This Session".
class DailySessionPlan {
  final String lessonType; // e.g. "Roleplay", "Fluency Challenge"
  final String level;
  final String objective;
  final List<SessionPhase> structure;
  final String dailyGoal; // e.g. "Speak for 10 minutes using 3 new expressions"
  final int totalMinutes;
  final DateTime generatedAt;

  DailySessionPlan({
    required this.lessonType,
    required this.level,
    required this.objective,
    required this.structure,
    required this.dailyGoal,
    required this.totalMinutes,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory DailySessionPlan.fromJson(Map<String, dynamic> json) =>
      DailySessionPlan(
        lessonType: json['lessonType'] as String,
        level: json['level'] as String,
        objective: json['objective'] as String,
        structure: (json['structure'] as List)
            .map((s) => SessionPhase.fromJson(s as Map<String, dynamic>))
            .toList(),
        dailyGoal: json['dailyGoal'] as String,
        totalMinutes: (json['totalMinutes'] as num).toInt(),
        generatedAt: json.containsKey('generatedAt')
            ? DateTime.parse(json['generatedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'lessonType': lessonType,
        'level': level,
        'objective': objective,
        'structure': structure.map((s) => s.toJson()).toList(),
        'dailyGoal': dailyGoal,
        'totalMinutes': totalMinutes,
        'generatedAt': generatedAt.toIso8601String(),
      };

  /// True once today's plan is more than 20 hours old — cheap way to
  /// decide whether to regenerate rather than tracking calendar days.
  bool get isStale =>
      DateTime.now().difference(generatedAt) > const Duration(hours: 20);
}
