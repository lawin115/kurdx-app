import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Custom Material Localizations delegate that supports Kurdish locales
/// by falling back to English for Material components
class KurdishMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support Kurdish locales by falling back to English
    return ['en', 'ar', 'ckb', 'ku'].contains(locale.languageCode);
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // For Kurdish locales, use English Material localizations
    if (locale.languageCode == 'ckb' || locale.languageCode == 'ku') {
      return const DefaultMaterialLocalizations();
    }
    
    // For other supported locales, use the default delegate
    const delegate = GlobalMaterialLocalizations.delegate;
    if (delegate.isSupported(locale)) {
      return delegate.load(locale);
    }
    
    // Fallback to English
    return const DefaultMaterialLocalizations();
  }

  @override
  bool shouldReload(KurdishMaterialLocalizationsDelegate old) => false;
}

/// Custom Cupertino Localizations delegate that supports Kurdish locales
/// by falling back to English for Cupertino components
class KurdishCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const KurdishCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support Kurdish locales by falling back to English
    return ['en', 'ar', 'ckb', 'ku'].contains(locale.languageCode);
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // For Kurdish locales, use English Cupertino localizations
    if (locale.languageCode == 'ckb' || locale.languageCode == 'ku') {
      return DefaultCupertinoLocalizations();
    }
    
    // For other supported locales, use the default delegate
    const delegate = GlobalCupertinoLocalizations.delegate;
    if (delegate.isSupported(locale)) {
      return delegate.load(locale);
    }
    
    // Fallback to English
    return DefaultCupertinoLocalizations();
  }

  @override
  bool shouldReload(KurdishCupertinoLocalizationsDelegate old) => false;
}