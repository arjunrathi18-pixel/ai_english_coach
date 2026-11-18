class SayItBetterResult {
  final String original;
  final String? correct;
  final String? natural;
  final String? professional;
  final String? casual;
  final String explanation;

  SayItBetterResult({
    required this.original,
    this.correct,
    this.natural,
    this.professional,
    this.casual,
    required this.explanation,
  });

  factory SayItBetterResult.fromJson(Map<String, dynamic> json) =>
      SayItBetterResult(
        original: json['original'] as String,
        correct: json['correct'] as String?,
        natural: json['natural'] as String?,
        professional: json['professional'] as String?,
        casual: json['casual'] as String?,
        explanation: json['explanation'] as String? ?? '',
      );

  /// True if the tool found nothing worth changing.
  bool get isAlreadyGood =>
      correct == null && natural == null && professional == null && casual == null;
}
