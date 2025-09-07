import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('en'); // Default to English
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  
  // Supported languages with their display names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ar': 'العربية',
    'ckb': 'کوردی سۆرانی',
    'ku': 'کوردی بادینی',
  };
  
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ar'), // Arabic
    Locale('ckb'), // Kurdish Sorani
    Locale('ku'), // Kurdish Badini
  ];
  
  LanguageProvider() {
    _loadLanguage();
  }
  
  // Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      if (languageCode != null && supportedLanguages.containsKey(languageCode)) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }
  
  // Change language and save to SharedPreferences
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      throw ArgumentError('Unsupported language code: $languageCode');
    }
    
    try {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    } catch (e) {
      print('Error saving language: $e');
    }
  }
  
  // Get display name for current language
  String getCurrentLanguageDisplayName() {
    return supportedLanguages[_currentLocale.languageCode] ?? 'English';
  }
  
  // Get display name for any language code
  String getLanguageDisplayName(String languageCode) {
    return supportedLanguages[languageCode] ?? 'Unknown';
  }
  
  // Check if current language is RTL (Right-to-Left)
  bool get isRTL {
    return _currentLocale.languageCode == 'ar' || 
           _currentLocale.languageCode == 'ckb' || 
           _currentLocale.languageCode == 'ku';
  }
  
  // Get text direction based on current language
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }
}