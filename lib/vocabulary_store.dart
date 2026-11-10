import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'vocabulary_item.dart';
import 'curriculum.dart' show MasteryStage;

class VocabularyStore {
  static const _key = 'vocabulary_profile_v1';

  static Future<List<VocabularyItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((v) => VocabularyItem.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<VocabularyItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((v) => v.toJson()).toList()),
    );
  }

  /// Adds a new item, or returns the existing one if this word/phrase is
  /// already tracked (case-insensitive) instead of duplicating it.
  static Future<VocabularyItem> upsertNew(VocabularyItem item) async {
    final all = await loadAll();
    final existingIndex = all.indexWhere(
      (v) => v.word.toLowerCase() == item.word.toLowerCase(),
    );
    if (existingIndex >= 0) {
      return all[existingIndex];
    }
    all.add(item);
    await saveAll(all);
    return item;
  }

  /// Persists an updated mastery/usage state for an existing item.
  static Future<void> update(VocabularyItem item) async {
    final all = await loadAll();
    final index = all.indexWhere(
      (v) => v.word.toLowerCase() == item.word.toLowerCase(),
    );
    if (index >= 0) {
      all[index] = item;
    } else {
      all.add(item);
    }
    await saveAll(all);
  }

  /// Words most worth reviewing next — not yet mastered, least recently
  /// practiced first (Prompt 7, section 46).
  static Future<List<VocabularyItem>> dueForReview({int limit = 10}) async {
    final all = await loadAll();
    final notMastered =
        all.where((v) => v.masteryStage != MasteryStage.mastered).toList();
    notMastered.sort((a, b) => a.lastPracticed.compareTo(b.lastPracticed));
    return notMastered.take(limit).toList();
  }
}
