import 'gamification_models.dart';
import 'gamification_store.dart';

/// Only meaningful learning completions should call this — never random
/// taps or app opens (Prompt 17, sections 1, 6: "anti-farming").
class GamificationService {
  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static int _daysBetween(String aIso, String bIso) {
    final a = DateTime.parse(aIso);
    final b = DateTime.parse(bIso);
    return b.difference(a).inDays;
  }

  /// Records one meaningful completion (end of chat session, roleplay,
  /// interview, listening passage, vocabulary/micro-lesson success).
  /// [xp] should reflect the value of the activity (Prompt 17, section 5 —
  /// higher-value learning gets more XP than trivial actions).
  static Future<LearnerStats> recordCompletion({required int xp}) async {
    final stats = await GamificationStore.load();
    final today = _todayIso();

    int newStreak = stats.currentStreak;
    if (stats.lastPracticeDateIso == null) {
      newStreak = 1;
    } else if (stats.lastPracticeDateIso == today) {
      // Already practiced today — streak unchanged, XP still counts.
      newStreak = stats.currentStreak == 0 ? 1 : stats.currentStreak;
    } else {
      final gap = _daysBetween(stats.lastPracticeDateIso!, today);
      if (gap == 1) {
        newStreak = stats.currentStreak + 1;
      } else {
        // Missed a day or more — streak resets, never shamed in the UI
        // (Prompt 17, section 20).
        newStreak = 1;
      }
    }

    final updated = LearnerStats(
      totalXp: stats.totalXp + xp,
      currentStreak: newStreak,
      bestStreak: newStreak > stats.bestStreak ? newStreak : stats.bestStreak,
      lastPracticeDateIso: today,
      totalSessionsCompleted: stats.totalSessionsCompleted + 1,
    );

    await GamificationStore.save(updated);
    return updated;
  }
}
