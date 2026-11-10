/// End-of-conversation feedback (Prompt 4, sections 37-38). This is shown
/// to the learner once, and its recurringMistakes feed straight into the
/// Personalized Learning Engine's mistake-recycling (Prompt 3, section 14).
class ConversationSummary {
  final String strongPoint;
  final String improvement;
  final String recommendation;
  final List<String> topicsDiscussed;
  final List<String> newExpressions;
  final List<String> corrections;
  final List<String> wordsToReview;
  final List<String> recurringMistakes;

  ConversationSummary({
    required this.strongPoint,
    required this.improvement,
    required this.recommendation,
    required this.topicsDiscussed,
    required this.newExpressions,
    required this.corrections,
    required this.wordsToReview,
    required this.recurringMistakes,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        strongPoint: json['strongPoint'] as String,
        improvement: json['improvement'] as String,
        recommendation: json['recommendation'] as String,
        topicsDiscussed: List<String>.from(json['topicsDiscussed'] as List),
        newExpressions: List<String>.from(json['newExpressions'] as List),
        corrections: List<String>.from(json['corrections'] as List),
        wordsToReview: List<String>.from(json['wordsToReview'] as List),
        recurringMistakes:
            List<String>.from(json['recurringMistakes'] as List),
      );

  Map<String, dynamic> toJson() => {
        'strongPoint': strongPoint,
        'improvement': improvement,
        'recommendation': recommendation,
        'topicsDiscussed': topicsDiscussed,
        'newExpressions': newExpressions,
        'corrections': corrections,
        'wordsToReview': wordsToReview,
        'recurringMistakes': recurringMistakes,
      };
}
