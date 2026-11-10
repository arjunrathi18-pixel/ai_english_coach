import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's theme mode (Dark / Light / System) and persists the
/// learner's choice locally (Prompt 11, section 5).
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode_v1';

  ThemeMode _mode = ThemeMode.dark; // dark is the flagship experience
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'system':
        _mode = ThemeMode.system;
        break;
      case 'dark':
      default:
        _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

/// A single shared instance — simple and sufficient for this app's size.
final themeController = ThemeController();
