import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'ar';
  Map<String, dynamic> _translations = {};

  String get currentLanguage => _currentLanguage;
  Map<String, dynamic> get translations => _translations;

  Future<void> loadTranslations() async {
    final String jsonString = await rootBundle.loadString(
      'lib/translations/$_currentLanguage.json',
    );
    _translations = json.decode(jsonString);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      await loadTranslations();
    }
  }

  String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _translations;

    for (String k in keys) {
      if (value is Map<String, dynamic>) {
        value = value[k];
      } else {
        return key;
      }
    }

    return value?.toString() ?? key;
  }
}
