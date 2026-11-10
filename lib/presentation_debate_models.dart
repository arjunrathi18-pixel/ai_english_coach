class PresentationOutline {
  final String title;
  final String opening;
  final List<String> mainPoints;
  final String conclusion;

  PresentationOutline({
    required this.title,
    required this.opening,
    required this.mainPoints,
    required this.conclusion,
  });

  factory PresentationOutline.fromJson(Map<String, dynamic> json) => PresentationOutline(
        title: json['title'] as String,
        opening: json['opening'] as String,
        mainPoints: List<String>.from(json['mainPoints'] as List? ?? []),
        conclusion: json['conclusion'] as String,
      );
}

class PresentationFeedback {
  final String structure;
  final String clarity;
  final String qaHandling;
  final String mainImprovement;

  PresentationFeedback({
    required this.structure,
    required this.clarity,
    required this.qaHandling,
    required this.mainImprovement,
  });

  factory PresentationFeedback.fromJson(Map<String, dynamic> json) => PresentationFeedback(
        structure: json['structure'] as String,
        clarity: json['clarity'] as String,
        qaHandling: json['qaHandling'] as String,
        mainImprovement: json['mainImprovement'] as String,
      );
}

class DebateFeedback {
  final String argumentClarity;
  final String reasoning;
  final String counterargumentHandling;
  final String mainImprovement;

  DebateFeedback({
    required this.argumentClarity,
    required this.reasoning,
    required this.counterargumentHandling,
    required this.mainImprovement,
  });

  factory DebateFeedback.fromJson(Map<String, dynamic> json) => DebateFeedback(
        argumentClarity: json['argumentClarity'] as String,
        reasoning: json['reasoning'] as String,
        counterargumentHandling: json['counterargumentHandling'] as String,
        mainImprovement: json['mainImprovement'] as String,
      );
}
