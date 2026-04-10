import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  bool _isDarkMode = false;
  static const _key = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key);
    if (saved != null) {
      _isDarkMode = saved;
    } else {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
  }
}

final themeService = ThemeService();
