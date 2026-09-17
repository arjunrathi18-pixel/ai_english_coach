class SkillScore {
  final int score; // 0-100
  final String level; // A0..C2

  SkillScore({required this.score, required this.level});

  factory SkillScore.fromJson(Map<String, dynamic> json) => SkillScore(
        score: (json['score'] as num).toInt(),
        level: json['level'] as String,
      );

  Map<String, dynamic> toJson() => {'score': score, 'level': level};
}

/// The full result of a Level Assessment session (Prompt 2).
/// This is what gets saved locally and handed to the main tutor engine
/// so it can start the learner at the right difficulty.
class LearnerProfile {
  final String overallLevel;
  final int confidence; // 0-100
  final Map<String, SkillScore> skills;
  final String mainStrength;
  final String mainWeakness;
  final List<String> recurringIssues;
  final String recommendedStartingPoint;
  final List<String> firstPriorities;
  final DateTime assessedAt;

  LearnerProfile({
    required this.overallLevel,
    required this.confidence,
    required this.skills,
    required this.mainStrength,
    required this.mainWeakness,
    required this.recurringIssues,
    required this.recommendedStartingPoint,
    required this.firstPriorities,
    DateTime? assessedAt,
  }) : assessedAt = assessedAt ?? DateTime.now();

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    final skillsJson = json['skills'] as Map<String, dynamic>;
    return LearnerProfile(
      overallLevel: json['overallLevel'] as String,
      confidence: (json['confidence'] as num).toInt(),
      skills: skillsJson.map(
        (key, value) =>
            MapEntry(key, SkillScore.fromJson(value as Map<String, dynamic>)),
      ),
      mainStrength: json['mainStrength'] as String,
      mainWeakness: json['mainWeakness'] as String,
      recurringIssues: List<String>.from(json['recurringIssues'] as List),
      recommendedStartingPoint: json['recommendedStartingPoint'] as String,
      firstPriorities: List<String>.from(json['firstPriorities'] as List),
      assessedAt: json.containsKey('assessedAt')
          ? DateTime.parse(json['assessedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'overallLevel': overallLevel,
        'confidence': confidence,
        'skills': skills.map((key, value) => MapEntry(key, value.toJson())),
        'mainStrength': mainStrength,
        'mainWeakness': mainWeakness,
        'recurringIssues': recurringIssues,
        'recommendedStartingPoint': recommendedStartingPoint,
        'firstPriorities': firstPriorities,
        'assessedAt': assessedAt.toIso8601String(),
      };
}
