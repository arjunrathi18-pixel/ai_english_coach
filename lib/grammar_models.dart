class GrammarDrill {
  final String topic;
  final String type; // fill_blank | transformation | sentence_building | error_spotting
  final String instruction;
  final String prompt;
  final String hint;

  /// Only set for built-in drills (used when the AI is unavailable), so the
  /// answer can be checked on the device without the AI.
  final List<String> acceptedAnswers;
  final String localExplanation;

  bool get isLocal => acceptedAnswers.isNotEmpty;

  GrammarDrill({
    required this.topic,
    required this.type,
    required this.instruction,
    required this.prompt,
    required this.hint,
    this.acceptedAnswers = const [],
    this.localExplanation = '',
  });

  factory GrammarDrill.fromJson(Map<String, dynamic> json) => GrammarDrill(
        topic: json['topic'] as String,
        type: json['type'] as String,
        instruction: json['instruction'] as String,
        prompt: json['prompt'] as String,
        hint: json['hint'] as String? ?? '',
      );
}

class GrammarEvalResult {
  final bool correct;
  final String correctAnswer;
  final String explanation;
  final String encouragement;

  GrammarEvalResult({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
    required this.encouragement,
  });

  factory GrammarEvalResult.fromJson(Map<String, dynamic> json) => GrammarEvalResult(
        correct: json['correct'] as bool,
        correctAnswer: json['correctAnswer'] as String,
        explanation: json['explanation'] as String,
        encouragement: json['encouragement'] as String? ?? '',
      );
}
