import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'app_theme_mode';

/// Persisted app theme (light/dark). Notifier so the app can rebuild when toggled.
class AppTheme {
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyThemeMode);
    if (index != null && index >= 0 && index <= 2) {
      notifier.value = ThemeMode.values[index];
    }
  }

  static ThemeMode get value => notifier.value;

  static Future<void> setThemeMode(ThemeMode mode) async {
    if (notifier.value == mode) return;
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  static Future<void> toggle() async {
    final next = notifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }

  static bool get isDark => notifier.value == ThemeMode.dark;
}
