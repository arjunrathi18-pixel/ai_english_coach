/// Gamification level is deliberately separate from CEFR English level
/// (Prompt 17, section 68 — never confuse the two).
class LearnerStats {
  final int totalXp;
  final int currentStreak;
  final int bestStreak;
  final String? lastPracticeDateIso; // yyyy-MM-dd, local date of last XP-earning activity
  final int totalSessionsCompleted;

  LearnerStats({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastPracticeDateIso,
    this.totalSessionsCompleted = 0,
  });

  factory LearnerStats.fromJson(Map<String, dynamic> json) => LearnerStats(
        totalXp: json['totalXp'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastPracticeDateIso: json['lastPracticeDateIso'] as String?,
        totalSessionsCompleted: json['totalSessionsCompleted'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastPracticeDateIso': lastPracticeDateIso,
        'totalSessionsCompleted': totalSessionsCompleted,
      };

  /// Gamification level — simple, transparent formula (100 XP per level).
  /// Never presented as an English proficiency measurement.
  int get level => 1 + (totalXp ~/ 100);

  String get levelTitle {
    const titles = [
      'First Step',
      'Getting Started',
      'Regular Speaker',
      'Consistent Learner',
      'Confident Speaker',
      'Conversation Builder',
      'Fluency Builder',
      'Advanced Communicator',
      'Professional Speaker',
    ];
    final index = level - 1;
    if (index < titles.length) return titles[index];
    return 'English Mastery Journey';
  }

  /// XP progress within the current level, for a progress bar (0.0-1.0).
  double get levelProgress => (totalXp % 100) / 100.0;
}
