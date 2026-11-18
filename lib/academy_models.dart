/// Offline Academy content models. All content is bundled in the app and
/// works with no internet and no AI. It is structured learning material,
/// not generative AI.

class AcademyLevel {
  final String id;
  final String name;
  final String hindi;
  final int order;
  const AcademyLevel(this.id, this.name, this.hindi, this.order);
}

const List<AcademyLevel> kAcademyLevels = [
  AcademyLevel('A0', 'Absolute Beginner', 'बिल्कुल शुरुआती', 0),
  AcademyLevel('A1', 'Beginner', 'शुरुआती', 1),
  AcademyLevel('A2', 'Elementary', 'प्रारंभिक', 2),
  AcademyLevel('B1', 'Intermediate', 'मध्यम', 3),
  AcademyLevel('B2', 'Upper Intermediate', 'उच्च मध्यम', 4),
  AcademyLevel('C1', 'Advanced', 'उन्नत', 5),
  AcademyLevel('C2', 'Proficient', 'निपुण', 6),
];

int academyLevelOrder(String id) =>
    kAcademyLevels.firstWhere((l) => l.id == id, orElse: () => kAcademyLevels.first).order;

class ExamplePair {
  final String en;
  final String hi;
  const ExamplePair(this.en, this.hi);
}

class WordPair {
  final String word;
  final String hindi;
  const WordPair(this.word, this.hindi);
}

class MistakePair {
  final String wrong;
  final String right;
  final String why;
  const MistakePair(this.wrong, this.right, this.why);
}

/// One multiple-choice question (grammar drill, reading check, quiz item).
class QuizItem {
  final String id;
  final String topic;
  final String level;
  final String question;
  final List<String> options;
  final int answer;
  final String why;
  const QuizItem(this.id, this.topic, this.level, this.question, this.options, this.answer, this.why);
}

class GrammarLesson {
  final String id;
  final String level;
  final String title;
  final String hindi;
  final String english;
  final String rule;
  final List<ExamplePair> examples;
  final List<MistakePair> mistakes;
  final List<QuizItem> drills;
  const GrammarLesson(this.id, this.level, this.title, this.hindi, this.english, this.rule,
      this.examples, this.mistakes, this.drills);
}

class AcademyWord {
  final String word;
  final String pos;
  final String hindi;
  final String meaning;
  final String example;
  final String level;
  final String category;
  final List<String> synonyms;
  final List<String> antonyms;
  const AcademyWord(this.word, this.pos, this.hindi, this.meaning, this.example, this.level,
      this.category, this.synonyms, this.antonyms);
}

class AcademySentence {
  final String id;
  final String en;
  final String hi;
  final String level;
  final String situation;
  final String alt;
  const AcademySentence(this.id, this.en, this.hi, this.level, this.situation, this.alt);
}

class InterviewItem {
  final String id;
  final String category;
  final String question;
  final String hindi;
  final String sample;
  final String professional;
  final List<String> vocab;
  final String structure;
  final String mistake;
  const InterviewItem(this.id, this.category, this.question, this.hindi, this.sample,
      this.professional, this.vocab, this.structure, this.mistake);
}

class RoleLine {
  final bool isMe;
  final String en;
  final String hi;
  const RoleLine(this.isMe, this.en, this.hi);
}

class RoleplayScenario {
  final String id;
  final String title;
  final String category;
  final String level;
  final String situation;
  final String userRole;
  final String otherRole;
  final List<RoleLine> dialogue;
  final List<WordPair> vocab;
  final List<String> phrases;
  final String task;
  const RoleplayScenario(this.id, this.title, this.category, this.level, this.situation, this.userRole,
      this.otherRole, this.dialogue, this.vocab, this.phrases, this.task);
}

class ReadingPassage {
  final String id;
  final String title;
  final String level;
  final String text;
  final String hindi;
  final List<WordPair> vocab;
  final List<QuizItem> questions;
  const ReadingPassage(this.id, this.title, this.level, this.text, this.hindi, this.vocab, this.questions);
}
