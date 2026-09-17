class ListeningQuestion {
  final String id;
  final String type; // main_idea | detail | inference | sequence | attitude
  final String text;
  final String expectedAnswerPoints;

  ListeningQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.expectedAnswerPoints,
  });

  factory ListeningQuestion.fromJson(Map<String, dynamic> json) =>
      ListeningQuestion(
        id: json['id'] as String,
        type: json['type'] as String,
        text: json['text'] as String,
        expectedAnswerPoints: json['expectedAnswerPoints'] as String,
      );
}

class ListeningPassage {
  final String topic;
  final String script;
  final List<ListeningQuestion> questions;

  ListeningPassage({
    required this.topic,
    required this.script,
    required this.questions,
  });

  factory ListeningPassage.fromJson(Map<String, dynamic> json) =>
      ListeningPassage(
        topic: json['topic'] as String,
        script: json['script'] as String,
        questions: (json['questions'] as List)
            .map((q) => ListeningQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

/// judgment is qualitative only — never a fabricated numeric score
/// (Prompt 8, sections 36 & 45).
enum AnswerJudgment { correct, partiallyCorrect, incorrect }

class ListeningAnswerResult {
  final AnswerJudgment judgment;
  final String feedback;
  final bool wasFirstAttempt; // tracked client-side (Prompt 8, section 37)

  ListeningAnswerResult({
    required this.judgment,
    required this.feedback,
    required this.wasFirstAttempt,
  });

  factory ListeningAnswerResult.fromJson(
    Map<String, dynamic> json, {
    required bool wasFirstAttempt,
  }) {
    final raw = json['judgment'] as String;
    final judgment = raw == 'correct'
        ? AnswerJudgment.correct
        : raw == 'partially_correct'
            ? AnswerJudgment.partiallyCorrect
            : AnswerJudgment.incorrect;
    return ListeningAnswerResult(
      judgment: judgment,
      feedback: json['feedback'] as String,
      wasFirstAttempt: wasFirstAttempt,
    );
  }
}
