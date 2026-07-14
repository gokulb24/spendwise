import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's theme-mode choice (system / light / dark) and persists it.
class ThemeController extends ChangeNotifier {
  static const _key = 'themeMode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == v,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } catch (_) {
      // ignore — fall back to system
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}
