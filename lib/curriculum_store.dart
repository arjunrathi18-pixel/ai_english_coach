import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'curriculum.dart';
import 'daily_session.dart';
import 'learning_goal.dart';

/// On-device storage for everything the Personalized Learning Engine needs
/// to remember between app launches: the goal the learner picked, their
/// generated roadmap, today's cached session plan, mastery progress, and
/// recurring mistakes to recycle into future lessons.
class CurriculumStore {
  static const _goalKey = 'learning_goal_v1';
  static const _roadmapKey = 'learning_roadmap_v1';
  static const _dailySessionKey = 'daily_session_v1';
  static const _masteryKey = 'mastery_map_v1';
  static const _mistakesKey = 'recurring_mistakes_v1';

  // ---- Goal ----
  static Future<void> saveGoal(GoalSelection goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, jsonEncode(goal.toJson()));
  }

  static Future<GoalSelection?> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalKey);
    if (raw == null) return null;
    return GoalSelection.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ---- Roadmap ----
  static Future<void> saveRoadmap(LearningRoadmap roadmap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roadmapKey, jsonEncode(roadmap.toJson()));
  }

  static Future<LearningRoadmap?> loadRoadmap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roadmapKey);
    if (raw == null) return null;
    try {
      return LearningRoadmap.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---- Daily session cache (regenerated once it goes stale) ----
  static Future<void> saveDailySession(DailySessionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailySessionKey, jsonEncode(plan.toJson()));
  }

  static Future<DailySessionPlan?> loadDailySession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailySessionKey);
    if (raw == null) return null;
    try {
      return DailySessionPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---- Mastery map: skill/topic name -> MasteryStage ----
  static Future<void> saveMastery(Map<String, MasteryStage> mastery) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = mastery.map((k, v) => MapEntry(k, v.name));
    await prefs.setString(_masteryKey, jsonEncode(encoded));
  }

  static Future<Map<String, MasteryStage>> loadMastery() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_masteryKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(
          k,
          MasteryStage.values.firstWhere(
            (s) => s.name == v,
            orElse: () => MasteryStage.notStarted,
          ),
        ));
  }

  // ---- Recurring mistakes ----
  static Future<void> saveMistakes(List<RecurringMistake> mistakes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mistakesKey,
      jsonEncode(mistakes.map((m) => m.toJson()).toList()),
    );
  }

  static Future<List<RecurringMistake>> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mistakesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((m) => RecurringMistake.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
