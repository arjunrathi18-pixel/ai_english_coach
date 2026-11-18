import 'academy_models.dart';
import 'academy_data_grammar.dart';
import 'academy_data_vocab.dart';
import 'academy_data_sentences.dart';
import 'academy_data_quiz.dart';
import 'academy_data_interview.dart';
import 'academy_data_roleplay.dart';
import 'academy_data_reading.dart';

class AcademySearchResults {
  final List<AcademyWord> words;
  final List<AcademySentence> sentences;
  final List<GrammarLesson> lessons;
  final List<InterviewItem> interviews;
  final List<ReadingPassage> passages;
  final String? lemmaNote;
  const AcademySearchResults(this.words, this.sentences, this.lessons, this.interviews, this.passages, this.lemmaNote);
  bool get isEmpty => words.isEmpty && sentences.isEmpty && lessons.isEmpty && interviews.isEmpty && passages.isEmpty;
}

/// Read-only access + search over the bundled offline content.
class AcademyRepository {
  static List<GrammarLesson> get lessons => kGrammarLessons;
  static List<AcademyWord> get words => kAcademyWords;
  static List<AcademySentence> get sentences => kAcademySentences;
  static List<InterviewItem> get interviews => kInterviewItems;
  static List<RoleplayScenario> get roleplays => kRoleplayScenarios;
  static List<ReadingPassage> get passages => kReadingPassages;

  /// Every static quiz item: grammar drills + extra bank + reading checks.
  static List<QuizItem> get staticQuizItems => [
        for (final l in kGrammarLessons) ...l.drills,
        ...kExtraQuizItems,
        for (final p in kReadingPassages) ...p.questions,
      ];

  static List<String> get wordCategories => (words.map((w) => w.category).toSet().toList()..sort());
  static List<String> get sentenceSituations => (sentences.map((s) => s.situation).toSet().toList());

  static Map<String, AcademyWord>? _byWord;
  static Map<String, AcademyWord> get _index {
    return _byWord ??= {for (final w in words) w.word.toLowerCase(): w};
  }

  /// Small, honest irregular-form table. A form is only mapped when the
  /// base word really exists in the offline word list — never guessed.
  static const Map<String, String> _irregular = {
    'went': 'go', 'gone': 'go', 'was': 'be', 'were': 'be', 'been': 'be', 'is': 'be', 'are': 'be', 'am': 'be',
    'had': 'have', 'has': 'have', 'did': 'do', 'does': 'do', 'done': 'do', 'said': 'say', 'saw': 'see',
    'seen': 'see', 'took': 'take', 'taken': 'take', 'made': 'make', 'came': 'come', 'got': 'get',
    'bought': 'buy', 'brought': 'bring', 'ran': 'run', 'ate': 'eat', 'eaten': 'eat', 'wrote': 'write',
    'written': 'write', 'children': 'child', 'men': 'man', 'women': 'woman', 'people': 'person',
    'feet': 'foot', 'teeth': 'tooth', 'mice': 'mouse', 'better': 'good', 'best': 'good', 'worse': 'bad',
    'worst': 'bad',
  };

  /// Possible base forms of [w] (running → run, went → go, children → child).
  static List<String> lemmaCandidates(String w) {
    final out = <String>[];
    void add(String s) {
      if (s.length >= 2 && s != w && !out.contains(s)) out.add(s);
    }

    final irr = _irregular[w];
    if (irr != null) add(irr);
    if (w.endsWith('ies') && w.length > 4) add('${w.substring(0, w.length - 3)}y');
    if (w.endsWith('ied') && w.length > 4) add('${w.substring(0, w.length - 3)}y');
    if (w.endsWith('ing') && w.length > 5) {
      final stem = w.substring(0, w.length - 3);
      add(stem);
      add('${stem}e');
      if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) add(stem.substring(0, stem.length - 1));
    }
    if (w.endsWith('ed') && w.length > 4) {
      final stem = w.substring(0, w.length - 2);
      add(stem);
      add('${stem}e');
      if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) add(stem.substring(0, stem.length - 1));
    }
    if (w.endsWith('es') && w.length > 3) add(w.substring(0, w.length - 2));
    if (w.endsWith('s') && w.length > 3) add(w.substring(0, w.length - 1));
    return out;
  }

  static String _norm(String s) => s.toLowerCase().trim();

  /// Word search: exact → base form → prefix → partial → Hindi/meaning.
  static List<AcademyWord> searchWords(String query, {String? category, String? level, String? pos}) {
    final q = _norm(query);
    bool filter(AcademyWord w) =>
        (category == null || w.category == category) &&
        (level == null || w.level == level) &&
        (pos == null || w.pos == pos);
    if (q.isEmpty) return words.where(filter).toList();

    final seen = <String>{};
    final out = <AcademyWord>[];
    void add(AcademyWord w) {
      if (filter(w) && seen.add(w.word)) out.add(w);
    }

    final exact = _index[q];
    if (exact != null) add(exact);
    for (final c in lemmaCandidates(q)) {
      final w = _index[c];
      if (w != null) add(w);
    }
    for (final w in words) {
      if (w.word.toLowerCase().startsWith(q)) add(w);
    }
    for (final w in words) {
      if (w.word.toLowerCase().contains(q)) add(w);
    }
    for (final w in words) {
      if (w.hindi.contains(query.trim()) || w.meaning.toLowerCase().contains(q)) add(w);
    }
    for (final w in words) {
      if (w.synonyms.any((s) => s.toLowerCase() == q) || w.antonyms.any((s) => s.toLowerCase() == q)) add(w);
    }
    return out;
  }

  /// A note like "went → go" shown ONLY when the base word was really found.
  static String? lemmaNote(String query) {
    final q = _norm(query);
    if (q.isEmpty || _index.containsKey(q)) return null;
    for (final c in lemmaCandidates(q)) {
      if (_index.containsKey(c)) return '"$q" is a form of "$c"';
    }
    return null;
  }

  static AcademySearchResults searchAll(String query) {
    final q = _norm(query);
    if (q.isEmpty) return const AcademySearchResults([], [], [], [], [], null);
    final raw = query.trim();
    return AcademySearchResults(
      searchWords(query).take(30).toList(),
      sentences.where((s) => s.en.toLowerCase().contains(q) || s.hi.contains(raw) || s.situation.toLowerCase().contains(q)).take(30).toList(),
      lessons.where((l) => l.title.toLowerCase().contains(q) || l.hindi.contains(raw) || l.english.toLowerCase().contains(q)).toList(),
      interviews.where((i) => i.question.toLowerCase().contains(q) || i.hindi.contains(raw) || i.category.toLowerCase().contains(q)).toList(),
      passages.where((p) => p.title.toLowerCase().contains(q) || p.text.toLowerCase().contains(q)).toList(),
      lemmaNote(query),
    );
  }

  static List<GrammarLesson> lessonsForLevel(String level) => lessons.where((l) => l.level == level).toList();
}
