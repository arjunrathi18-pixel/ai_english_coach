class GrammarDrill {
  final String topic;
  final String type; // fill_blank | transformation | sentence_building | error_spotting
  final String instruction;
  final String prompt;
  final String hint;

  GrammarDrill({
    required this.topic,
    required this.type,
    required this.instruction,
    required this.prompt,
    required this.hint,
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
