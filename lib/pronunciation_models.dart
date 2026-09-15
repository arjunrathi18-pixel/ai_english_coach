class PhoneticInfo {
  final String word;
  final String ipa;
  final String simpleSpelling;
  final List<String> syllables;
  final int stressedSyllableIndex;
  final String tip;

  PhoneticInfo({
    required this.word,
    required this.ipa,
    required this.simpleSpelling,
    required this.syllables,
    required this.stressedSyllableIndex,
    required this.tip,
  });

  factory PhoneticInfo.fromJson(Map<String, dynamic> json) => PhoneticInfo(
        word: json['word'] as String,
        ipa: json['ipa'] as String,
        simpleSpelling: json['simpleSpelling'] as String,
        syllables: List<String>.from(json['syllables'] as List),
        stressedSyllableIndex: (json['stressedSyllableIndex'] as num).toInt(),
        tip: json['tip'] as String,
      );
}

class ShadowingFeedback {
  final bool reliable;
  final String matchSummary;
  final String topFocus;
  final String encouragement;
  final bool readyForNextLevel;

  ShadowingFeedback({
    required this.reliable,
    required this.matchSummary,
    required this.topFocus,
    required this.encouragement,
    required this.readyForNextLevel,
  });

  factory ShadowingFeedback.fromJson(Map<String, dynamic> json) =>
      ShadowingFeedback(
        reliable: json['reliable'] as bool,
        matchSummary: json['matchSummary'] as String,
        topFocus: json['topFocus'] as String? ?? '',
        encouragement: json['encouragement'] as String? ?? '',
        readyForNextLevel: json['readyForNextLevel'] as bool? ?? false,
      );
}

class MinimalPair {
  final String a;
  final String b;
  MinimalPair({required this.a, required this.b});

  factory MinimalPair.fromJson(Map<String, dynamic> json) =>
      MinimalPair(a: json['a'] as String, b: json['b'] as String);
}

class MinimalPairSet {
  final String contrastLabel;
  final List<MinimalPair> pairs;

  MinimalPairSet({required this.contrastLabel, required this.pairs});

  factory MinimalPairSet.fromJson(Map<String, dynamic> json) =>
      MinimalPairSet(
        contrastLabel: json['contrastLabel'] as String,
        pairs: (json['pairs'] as List)
            .map((p) => MinimalPair.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
