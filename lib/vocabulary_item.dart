import 'curriculum.dart' show MasteryStage;

/// One vocabulary item in the learner's personal vocabulary profile
/// (Prompt 7, sections 2, 21, 47). Mastery only advances through
/// demonstrated correct, natural use — never from lookup alone.
class VocabularyItem {
  final String word;
  final String category; // word | phrasal_verb | idiom | collocation | expression
  final String meaning;
  final String simpleExplanation;
  final List<String> examples;
  final List<String> collocations;
  final String register;
  final String nuanceOrSynonyms;
  final String practicePrompt;

  MasteryStage masteryStage;
  int timesUsedCorrectly;
  DateTime lastPracticed;
  DateTime firstAdded;

  VocabularyItem({
    required this.word,
    required this.category,
    required this.meaning,
    required this.simpleExplanation,
    required this.examples,
    required this.collocations,
    required this.register,
    required this.nuanceOrSynonyms,
    required this.practicePrompt,
    this.masteryStage = MasteryStage.introduced,
    this.timesUsedCorrectly = 0,
    DateTime? lastPracticed,
    DateTime? firstAdded,
  })  : lastPracticed = lastPracticed ?? DateTime.now(),
        firstAdded = firstAdded ?? DateTime.now();

  factory VocabularyItem.fromJson(Map<String, dynamic> json) => VocabularyItem(
        word: json['word'] as String,
        category: json['category'] as String,
        meaning: json['meaning'] as String,
        simpleExplanation: json['simpleExplanation'] as String,
        examples: List<String>.from(json['examples'] as List),
        collocations: List<String>.from(json['collocations'] as List? ?? []),
        register: json['register'] as String? ?? '',
        nuanceOrSynonyms: json['nuanceOrSynonyms'] as String? ?? '',
        practicePrompt: json['practicePrompt'] as String,
        masteryStage: MasteryStage.values.firstWhere(
          (s) => s.name == (json['masteryStage'] as String? ?? 'introduced'),
          orElse: () => MasteryStage.introduced,
        ),
        timesUsedCorrectly: json['timesUsedCorrectly'] as int? ?? 0,
        lastPracticed: json['lastPracticed'] != null
            ? DateTime.parse(json['lastPracticed'] as String)
            : DateTime.now(),
        firstAdded: json['firstAdded'] != null
            ? DateTime.parse(json['firstAdded'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'category': category,
        'meaning': meaning,
        'simpleExplanation': simpleExplanation,
        'examples': examples,
        'collocations': collocations,
        'register': register,
        'nuanceOrSynonyms': nuanceOrSynonyms,
        'practicePrompt': practicePrompt,
        'masteryStage': masteryStage.name,
        'timesUsedCorrectly': timesUsedCorrectly,
        'lastPracticed': lastPracticed.toIso8601String(),
        'firstAdded': firstAdded.toIso8601String(),
      };

  /// Advance one stage after a successful, natural use — never jump
  /// straight to mastered from a single attempt (Prompt 7, section 47).
  void registerSuccessfulUse() {
    timesUsedCorrectly += 1;
    lastPracticed = DateTime.now();
    const order = MasteryStage.values;
    final currentIndex = order.indexOf(masteryStage);
    if (currentIndex < order.length - 1) {
      masteryStage = order[currentIndex + 1];
    }
  }

  void registerAttemptWithoutSuccess() {
    lastPracticed = DateTime.now();
  }
}
