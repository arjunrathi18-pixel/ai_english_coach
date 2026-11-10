class DailyChallenge {
  final String title;
  final String type;
  final String why;
  final String objective;
  final String dailyGoal;
  final List<String> steps;

  DailyChallenge({
    required this.title,
    required this.type,
    required this.why,
    required this.objective,
    required this.dailyGoal,
    required this.steps,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        title: json['title'] as String,
        type: json['type'] as String,
        why: json['why'] as String? ?? '',
        objective: json['objective'] as String,
        dailyGoal: json['dailyGoal'] as String,
        steps: List<String>.from(json['steps'] as List? ?? []),
      );
}
