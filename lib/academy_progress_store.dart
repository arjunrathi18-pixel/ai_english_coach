import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuizRecord {
  final String topic;
  final int correct;
  final int total;
  final int ts;
  const QuizRecord(this.topic, this.correct, this.total, this.ts);
  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
  Map<String, dynamic> toJson() => {'t': topic, 'c': correct, 'n': total, 'ts': ts};
  factory QuizRecord.fromJson(Map<String, dynamic> j) =>
      QuizRecord(j['t'] as String, j['c'] as int, j['n'] as int, j['ts'] as int);
}

/// Everything the learner has done in the Offline Academy. Saved on the
/// device only, so it survives restarts and works with no internet.
class AcademyProgress {
  Set<String> completedLessons = {};
  Map<String, int> lessonBest = {};
  Set<String> favorites = {};
  Map<String, int> srBox = {}; // word -> Leitner box 1..5
  Map<String, int> srDue = {}; // word -> day number
  List<QuizRecord> quizHistory = [];
  Set<String> readingDone = {};
  Set<String> interviewDone = {};
  Set<String> roleplayDone = {};
  Set<String> speakingDone = {}; // sentence/line ids practised aloud
  int seconds = 0; // time spent in the Academy
  int streak = 0;
  int bestStreak = 0;
  int lastDay = -1;
  int unlockedUpTo = 0; // highest level index the learner may open (0 = A0)
  int dailyWordGoal = 10;

  static const List<int> intervals = [1, 2, 4, 8, 16];

  static int today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).difference(DateTime(1970)).inDays;
  }

  int get minutes => seconds ~/ 60;
  int get wordsMastered => srBox.values.where((b) => b >= 5).length;
  int get wordsStarted => srBox.length;

  List<String> dueWords() {
    final t = today();
    return srDue.entries.where((e) => e.value <= t).map((e) => e.key).toList();
  }

  /// Counts as a streak day when the learner does something meaningful.
  void touch() {
    final t = today();
    if (lastDay == t) return;
    streak = (lastDay == t - 1) ? streak + 1 : 1;
    if (streak > bestStreak) bestStreak = streak;
    lastDay = t;
  }

  void reviewWord(String word, bool correct) {
    final box = srBox[word] ?? 0;
    final next = correct ? (box + 1).clamp(1, 5).toInt() : 1;
    srBox[word] = next;
    srDue[word] = today() + intervals[next - 1];
    touch();
  }

  void recordQuiz(String topic, int correct, int total) {
    quizHistory.add(QuizRecord(topic, correct, total, DateTime.now().millisecondsSinceEpoch));
    if (quizHistory.length > 300) quizHistory = quizHistory.sublist(quizHistory.length - 300);
    touch();
  }

  /// Topics whose recent results are below 60% (needs at least 1 attempt).
  List<String> weakTopics() {
    final byTopic = <String, List<QuizRecord>>{};
    for (final r in quizHistory) {
      byTopic.putIfAbsent(r.topic, () => []).add(r);
    }
    final weak = <String>[];
    byTopic.forEach((topic, list) {
      final recent = list.length > 3 ? list.sublist(list.length - 3) : list;
      final c = recent.fold<int>(0, (a, r) => a + r.correct);
      final n = recent.fold<int>(0, (a, r) => a + r.total);
      if (n > 0 && c * 100 / n < 60) weak.add(topic);
    });
    return weak;
  }

  Map<String, dynamic> toJson() => {
        'lessons': completedLessons.toList(),
        'best': lessonBest,
        'fav': favorites.toList(),
        'box': srBox,
        'due': srDue,
        'quiz': quizHistory.map((q) => q.toJson()).toList(),
        'read': readingDone.toList(),
        'intv': interviewDone.toList(),
        'role': roleplayDone.toList(),
        'speak': speakingDone.toList(),
        'sec': seconds,
        'streak': streak,
        'bestStreak': bestStreak,
        'lastDay': lastDay,
        'unlocked': unlockedUpTo,
        'goal': dailyWordGoal,
      };

  static AcademyProgress fromJson(Map<String, dynamic> j) {
    final p = AcademyProgress();
    Set<String> s(String k) => Set<String>.from((j[k] as List?) ?? const []);
    Map<String, int> m(String k) =>
        Map<String, int>.from(((j[k] as Map?) ?? const {}).map((a, b) => MapEntry(a as String, (b as num).toInt())));
    p.completedLessons = s('lessons');
    p.lessonBest = m('best');
    p.favorites = s('fav');
    p.srBox = m('box');
    p.srDue = m('due');
    p.quizHistory = ((j['quiz'] as List?) ?? const [])
        .map((e) => QuizRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    p.readingDone = s('read');
    p.interviewDone = s('intv');
    p.roleplayDone = s('role');
    p.speakingDone = s('speak');
    p.seconds = (j['sec'] as int?) ?? 0;
    p.streak = (j['streak'] as int?) ?? 0;
    p.bestStreak = (j['bestStreak'] as int?) ?? 0;
    p.lastDay = (j['lastDay'] as int?) ?? -1;
    p.unlockedUpTo = (j['unlocked'] as int?) ?? 0;
    p.dailyWordGoal = (j['goal'] as int?) ?? 10;
    return p;
  }
}

class AcademyProgressStore {
  static const _key = 'academy_progress_v1';
  static AcademyProgress? _cache;

  static Future<AcademyProgress> load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _cache = AcademyProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return _cache!;
      } catch (_) {
        // corrupt data: keep a backup copy instead of silently deleting it
        await prefs.setString('${_key}_corrupt_backup', raw);
      }
    }
    _cache = AcademyProgress();
    return _cache!;
  }

  static Future<void> save() async {
    final p = await load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }

  /// Change progress and persist it in one step.
  static Future<AcademyProgress> update(void Function(AcademyProgress p) change) async {
    final p = await load();
    change(p);
    await save();
    return p;
  }

  static Future<void> addSeconds(int s) async {
    if (s <= 0) return;
    await update((p) => p.seconds += s);
  }

  static void resetCacheForTests() => _cache = null;
}
