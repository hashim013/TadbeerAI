import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _settingsBox = 'app_settings';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationKey = 'notifications_enabled';

  /// Initialize Hive
  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_settingsBox);
  }

  /// Get the theme mode from local storage
  static Future<ThemeMode> getThemeMode() async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      final dynamic val = box.get(_themeKey);
      final themeModeString = val?.toString() ?? 'light';
      return themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('Error reading theme mode: $e');
      return ThemeMode.light;
    }
  }

  /// Save the theme mode to local storage
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.put(_themeKey, themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Get the app language from local storage
  static Future<String> getLanguage() async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      final dynamic val = box.get(_languageKey);
      return val?.toString() ?? 'en';
    } catch (e) {
      debugPrint('Error reading language: $e');
      return 'en';
    }
  }

  /// Save the app language to local storage
  static Future<void> saveLanguage(String language) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.put(_languageKey, language);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> isNotificationsEnabled() async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      final dynamic val = box.get(_notificationKey);
      if (val is bool) return val;
      if (val == null) return true;
      return val.toString().toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error reading notifications setting: $e');
      return true;
    }
  }

  /// Enable or disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.put(_notificationKey, enabled);
    } catch (e) {
      debugPrint('Error saving notifications setting: $e');
    }
  }

  /// Save a custom setting
  static Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.put(key, value);
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
    }
  }

  /// Get a custom setting
  static Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('Error reading setting $key: $e');
      return defaultValue;
    }
  }

  /// Clear all settings
  static Future<void> clearAllSettings() async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.clear();
    } catch (e) {
      debugPrint('Error clearing settings: $e');
    }
  }

  /// Delete a specific setting
  static Future<void> deleteSetting(String key) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.delete(key);
    } catch (e) {
      debugPrint('Error deleting setting $key: $e');
    }
  }
}
