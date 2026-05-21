import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider({ThemeMode initialTheme = ThemeMode.light}) : _themeMode = initialTheme;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await HiveService.saveThemeMode(_themeMode);
    notifyListeners();
  }
}
