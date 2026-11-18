import 'dart:math';
import 'academy_models.dart';
import 'academy_repository.dart';

/// Builds quizzes from verified content. Vocabulary questions are generated
/// from the word list, so the answer key is correct by construction.
class AcademyQuizEngine {
  static List<QuizItem> vocabularyQuestions(int count, {Random? random}) {
    final rnd = random ?? Random();
    final words = [...AcademyRepository.words]..shuffle(rnd);
    final out = <QuizItem>[];
    for (var i = 0; i < words.length && out.length < count; i++) {
      final w = words[i];
      final toHindi = i.isEven;
      final pool = AcademyRepository.words.where((x) => x.word != w.word && x.pos == w.pos).toList()..shuffle(rnd);
      final correct = toHindi ? w.hindi : w.word;
      final distractors = <String>[];
      for (final x in pool) {
        final v = toHindi ? x.hindi : x.word;
        if (v != correct && !distractors.contains(v)) distractors.add(v);
        if (distractors.length == 3) break;
      }
      if (distractors.length < 3) continue;
      final options = [correct, ...distractors]..shuffle(rnd);
      out.add(QuizItem(
        'vq_${w.word}_${toHindi ? 'h' : 'e'}',
        'Vocabulary',
        w.level,
        toHindi ? 'What is the Hindi meaning of "${w.word}"?' : 'Which word means: ${w.meaning}?',
        options,
        options.indexOf(correct),
        '${w.word} = ${w.hindi} — ${w.meaning}.',
      ));
    }
    return out;
  }

  static List<String> topics() {
    final t = AcademyRepository.staticQuizItems.map((q) => q.topic).toSet().toList()..sort();
    return ['Vocabulary', ...t];
  }

  static List<QuizItem> build({String? topic, int count = 10, Random? random}) {
    final rnd = random ?? Random();
    List<QuizItem> pool;
    if (topic == 'Vocabulary') {
      return vocabularyQuestions(count, random: rnd);
    } else if (topic == null) {
      pool = [...AcademyRepository.staticQuizItems, ...vocabularyQuestions(10, random: rnd)];
    } else {
      pool = AcademyRepository.staticQuizItems.where((q) => q.topic == topic).toList();
    }
    pool.shuffle(rnd);
    return pool.take(count).toList();
  }

  static int percent(int correct, int total) => total == 0 ? 0 : (correct * 100 / total).round();
}
