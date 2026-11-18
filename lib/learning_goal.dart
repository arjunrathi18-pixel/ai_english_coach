/// The learner's chosen focus for their learning journey (Prompt 3, section 4 & 29).
enum LearningGoal {
  generalSpeaking,
  dailyConversation,
  careerGrowth,
  jobInterview,
  businessEnglish,
  travelEnglish,
  academicEnglish,
  pronunciationFocus,
  nativeLikeFluency,
}

extension LearningGoalLabel on LearningGoal {
  String get label {
    switch (this) {
      case LearningGoal.generalSpeaking:
        return 'General Speaking';
      case LearningGoal.dailyConversation:
        return 'Daily Conversation';
      case LearningGoal.careerGrowth:
        return 'Career Growth';
      case LearningGoal.jobInterview:
        return 'Job Interview Prep';
      case LearningGoal.businessEnglish:
        return 'Business English';
      case LearningGoal.travelEnglish:
        return 'Travel English';
      case LearningGoal.academicEnglish:
        return 'Academic English';
      case LearningGoal.pronunciationFocus:
        return 'Pronunciation Focus';
      case LearningGoal.nativeLikeFluency:
        return 'Native-like Fluency';
    }
  }

  /// Stable key sent to the AI / stored on disk — keep this constant even
  /// if the display label changes later.
  String get key => toString().split('.').last;

  static LearningGoal fromKey(String key) {
    return LearningGoal.values.firstWhere(
      (g) => g.key == key,
      orElse: () => LearningGoal.generalSpeaking,
    );
  }
}

/// What the learner picked, plus how much time they have.
/// Feeds directly into LearningEngineService.generateRoadmap().
class GoalSelection {
  final LearningGoal primaryGoal;
  final LearningGoal? secondaryGoal;
  final int dailyMinutesAvailable;

  GoalSelection({
    required this.primaryGoal,
    this.secondaryGoal,
    this.dailyMinutesAvailable = 15,
  });

  Map<String, dynamic> toJson() => {
        'primaryGoal': primaryGoal.key,
        'secondaryGoal': secondaryGoal?.key,
        'dailyMinutesAvailable': dailyMinutesAvailable,
      };

  factory GoalSelection.fromJson(Map<String, dynamic> json) => GoalSelection(
        primaryGoal: LearningGoalLabel.fromKey(json['primaryGoal'] as String),
        secondaryGoal: json['secondaryGoal'] != null
            ? LearningGoalLabel.fromKey(json['secondaryGoal'] as String)
            : null,
        dailyMinutesAvailable: json['dailyMinutesAvailable'] as int? ?? 15,
      );
}
