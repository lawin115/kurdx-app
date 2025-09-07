import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isIOS26Style = false;

  ThemeMode get themeMode => _themeMode;
  bool get isIOS26Style => _isIOS26Style;

  ThemeProvider() {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    final iosStyle = prefs.getBool('ios26Style') ?? false;
    
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    
    _isIOS26Style = iosStyle;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }
  
  void setIOS26Style(bool enabled) async {
    if (_isIOS26Style == enabled) return;
    _isIOS26Style = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ios26Style', enabled);
    notifyListeners();
  }
}