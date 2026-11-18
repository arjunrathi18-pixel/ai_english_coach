import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'learner_profile.dart';

/// Saves/loads the learner's most recent assessment result on-device.
/// Later prompts (Personalized Learning Engine, Progress tracking) will
/// extend this into a fuller Learner Profile Engine — this is deliberately
/// minimal for now.
class ProfileStore {
  static const _key = 'learner_profile_v1';

  static Future<void> save(LearnerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static Future<LearnerProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return LearnerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
