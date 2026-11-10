import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'gamification_models.dart';

class GamificationStore {
  static const _key = 'learner_stats_v1';

  static Future<LearnerStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return LearnerStats();
    try {
      return LearnerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return LearnerStats();
    }
  }

  static Future<void> save(LearnerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(stats.toJson()));
  }
}
