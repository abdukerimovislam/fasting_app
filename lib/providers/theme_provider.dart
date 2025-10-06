// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // --- NEW: Add Locale property ---
  Locale? _appLocale;
  Locale? get appLocale => _appLocale;

  ThemeProvider() {
    _loadPreferences(); // Renamed for clarity
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final themeIndex = prefs.getInt('themeMode') ?? 2;
    _themeMode = ThemeMode.values[themeIndex];

    // --- NEW: Load saved language ---
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      _appLocale = Locale(languageCode);
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  // --- NEW: Function to change and save the locale ---
  void setLocale(Locale locale) async {
    _appLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCode', locale.languageCode);
    notifyListeners();
    print('--- Language state changed to: ${locale.languageCode} ---');
  }
}