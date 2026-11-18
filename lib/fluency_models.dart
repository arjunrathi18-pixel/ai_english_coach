class OneMinuteFeedback {
  final String strength;
  final String mainIssue;
  final String practiceTip;
  OneMinuteFeedback({required this.strength, required this.mainIssue, required this.practiceTip});

  factory OneMinuteFeedback.fromJson(Map<String, dynamic> json) => OneMinuteFeedback(
        strength: json['strength'] as String,
        mainIssue: json['mainIssue'] as String,
        practiceTip: json['practiceTip'] as String,
      );
}

class CircumlocutionEval {
  final bool wouldGuessCorrectly;
  final String feedback;
  CircumlocutionEval({required this.wouldGuessCorrectly, required this.feedback});

  factory CircumlocutionEval.fromJson(Map<String, dynamic> json) => CircumlocutionEval(
        wouldGuessCorrectly: json['wouldGuessCorrectly'] as bool,
        feedback: json['feedback'] as String,
      );
}
