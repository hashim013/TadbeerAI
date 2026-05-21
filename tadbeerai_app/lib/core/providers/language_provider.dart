import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _language;

  LanguageProvider({String initialLanguage = 'en'}) : _language = initialLanguage;

  String get language => _language;

  bool get isUrdu => _language == 'ur';
  bool get isRomanUrdu => _language == 'roman_ur';
  bool get isEnglish => _language == 'en';

  Future<void> setLanguage(String lang) async {
    if (_language != lang) {
      _language = lang;
      await HiveService.saveLanguage(lang);
      notifyListeners();
    }
  }
}
