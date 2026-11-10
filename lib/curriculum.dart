/// One week's worth of the roadmap (Prompt 3, section 5 & 27).
class RoadmapWeek {
  final int weekNumber;
  final String focus;
  final String details;

  RoadmapWeek({
    required this.weekNumber,
    required this.focus,
    required this.details,
  });

  factory RoadmapWeek.fromJson(Map<String, dynamic> json) => RoadmapWeek(
        weekNumber: (json['weekNumber'] as num).toInt(),
        focus: json['focus'] as String,
        details: json['details'] as String,
      );

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'focus': focus,
        'details': details,
      };
}

/// The learner's personalized multi-week learning roadmap, generated once
/// from their assessment profile + goal, and regenerated at reassessment
/// time (Prompt 3, section 28).
class LearningRoadmap {
  final String currentLevel;
  final String targetLevel;
  final String primaryGoal;
  final List<String> priorities;
  final int dailyPracticeMinutes;
  final String reassessmentSchedule;
  final List<RoadmapWeek> weeks;
  final DateTime generatedAt;

  LearningRoadmap({
    required this.currentLevel,
    required this.targetLevel,
    required this.primaryGoal,
    required this.priorities,
    required this.dailyPracticeMinutes,
    required this.reassessmentSchedule,
    required this.weeks,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory LearningRoadmap.fromJson(Map<String, dynamic> json) =>
      LearningRoadmap(
        currentLevel: json['currentLevel'] as String,
        targetLevel: json['targetLevel'] as String,
        primaryGoal: json['primaryGoal'] as String,
        priorities: List<String>.from(json['priorities'] as List),
        dailyPracticeMinutes: (json['dailyPracticeMinutes'] as num).toInt(),
        reassessmentSchedule: json['reassessmentSchedule'] as String,
        weeks: (json['weeks'] as List)
            .map((w) => RoadmapWeek.fromJson(w as Map<String, dynamic>))
            .toList(),
        generatedAt: json.containsKey('generatedAt')
            ? DateTime.parse(json['generatedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'targetLevel': targetLevel,
        'primaryGoal': primaryGoal,
        'priorities': priorities,
        'dailyPracticeMinutes': dailyPracticeMinutes,
        'reassessmentSchedule': reassessmentSchedule,
        'weeks': weeks.map((w) => w.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };
}

/// Mastery progression for a single skill/topic (Prompt 3, section 13).
enum MasteryStage {
  notStarted,
  introduced,
  practicing,
  developing,
  competent,
  mastered,
}

extension MasteryStageLabel on MasteryStage {
  String get label {
    switch (this) {
      case MasteryStage.notStarted:
        return 'Not Started';
      case MasteryStage.introduced:
        return 'Introduced';
      case MasteryStage.practicing:
        return 'Practicing';
      case MasteryStage.developing:
        return 'Developing';
      case MasteryStage.competent:
        return 'Competent';
      case MasteryStage.mastered:
        return 'Mastered';
    }
  }
}

/// Tracks recurring mistakes so the engine can recycle them into future
/// lessons (Prompt 3, section 14) instead of forgetting them.
class RecurringMistake {
  final String pattern; // e.g. "third-person singular (he go -> he goes)"
  final int timesObserved;
  final DateTime lastObserved;

  RecurringMistake({
    required this.pattern,
    required this.timesObserved,
    DateTime? lastObserved,
  }) : lastObserved = lastObserved ?? DateTime.now();

  factory RecurringMistake.fromJson(Map<String, dynamic> json) =>
      RecurringMistake(
        pattern: json['pattern'] as String,
        timesObserved: json['timesObserved'] as int,
        lastObserved: DateTime.parse(json['lastObserved'] as String),
      );

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'timesObserved': timesObserved,
        'lastObserved': lastObserved.toIso8601String(),
      };
}
