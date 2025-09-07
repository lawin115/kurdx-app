// lib/utils/ios26_theme.dart
import 'package:flutter/material.dart';

// iOS 26 Style Color Palette
const Color iosBlue = Color(0xFF007AFF);
const Color iosGreen = Color(0xFF34C759);
const Color iosIndigo = Color(0xFF5856D6);
const Color iosOrange = Color(0xFFFF9500);
const Color iosPink = Color(0xFFFF2D55);
const Color iosPurple = Color(0xFFAF52DE);
const Color iosRed = Color(0xFFFF3B30);
const Color iosTeal = Color(0xFF5AC8FA);
const Color iosYellow = Color(0xFFFFCC00);

// Light Theme Colors
const Color lightBackground = Color(0xFFF2F2F7);
const Color lightSurface = Color(0xFFFFFFFF);
const Color lightPrimaryText = Color(0xFF000000);
const Color lightSecondaryText = Color(0xFF8E8E93);
const Color lightSystemGray = Color(0xFF8E8E93);
const Color lightSystemGray2 = Color(0xFFAEAEB2);
const Color lightSystemGray3 = Color(0xFFC7C7CC);
const Color lightSystemGray4 = Color(0xFFD1D1D6);
const Color lightSystemGray5 = Color(0xFFE5E5EA);
const Color lightSystemGray6 = Color(0xFFF2F2F7);
const Color lightSeparator = Color(0xFFD1D1D6);

// Dark Theme Colors
const Color darkBackground = Color(0xFF000000);
const Color darkSurface = Color(0xFF1C1C1E);
const Color darkPrimaryText = Color(0xFFFFFFFF);
const Color darkSecondaryText = Color(0xFF8E8E93);
const Color darkSystemGray = Color(0xFF8E8E93);
const Color darkSystemGray2 = Color(0xFF636366);
const Color darkSystemGray3 = Color(0xFF48484A);
const Color darkSystemGray4 = Color(0xFF3A3A3C);
const Color darkSystemGray5 = Color(0xFF2C2C2E);
const Color darkSystemGray6 = Color(0xFF1C1C1E);
const Color darkSeparator = Color(0xFF38383A);

class IOS26Theme {
  /// Creates a text theme following iOS 26 design guidelines
  static TextTheme buildIOSTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primaryColor = isDark ? darkPrimaryText : lightPrimaryText;
    final Color secondaryColor = isDark ? darkSecondaryText : lightSecondaryText;
    
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.1,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.25,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.33,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.25,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.33,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.38,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.25,
      ),
      labelMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        height: 1.38,
      ),
    );
  }

  /// Creates an elevated button theme following iOS 26 design guidelines
  static ElevatedButtonThemeData buildIOSButtonTheme(Color primaryColor, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color backgroundColor = isDark ? darkSurface : lightSurface;
    final Color foregroundColor = primaryColor;
    final Color borderColor = isDark ? darkSeparator : lightSeparator;
    
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        minimumSize: const Size(double.infinity, 50),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return primaryColor.withOpacity(0.1);
            }
            return null;
          },
        ),
      ),
    );
  }

  /// Creates an app bar theme following iOS 26 design guidelines
  static AppBarTheme buildIOSAppBarTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color backgroundColor = isDark ? darkBackground : lightBackground;
    final Color foregroundColor = isDark ? darkPrimaryText : lightPrimaryText;
    
    return AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: foregroundColor,
      ),
      toolbarHeight: 44,
      centerTitle: true,
    );
  }

  /// Creates a bottom navigation theme following iOS 26 design guidelines
  static BottomNavigationBarThemeData buildIOSBottomNavTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color backgroundColor = isDark ? darkBackground : lightBackground;
    final Color selectedItemColor = iosBlue;
    final Color unselectedItemColor = isDark ? darkSystemGray : lightSystemGray;
    
    return BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    );
  }

  /// Creates an input decoration theme following iOS 26 design guidelines
  static InputDecorationTheme buildIOSInputDecorationTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color fillColor = isDark ? darkSurface : lightSurface;
    final Color borderColor = isDark ? darkSeparator : lightSeparator;
    final Color textColor = isDark ? darkSecondaryText : lightSecondaryText;
    
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: iosBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(
        color: textColor,
      ),
    );
  }

  /// Creates a card theme following iOS 26 design guidelines
  static CardThemeData buildIOSCardTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color color = isDark ? darkSurface : lightSurface;
    final Color borderColor = isDark ? darkSeparator : lightSeparator;
    
    return const CardThemeData().copyWith(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 0.5),
      ),
    );
  }

  /// Creates a list tile theme following iOS 26 design guidelines
  static ListTileThemeData buildIOSListTileTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color tileColor = isDark ? darkSurface : lightSurface;
    final Color iconColor = isDark ? darkPrimaryText : lightPrimaryText;
    final Color textColor = isDark ? darkPrimaryText : lightPrimaryText;
    
    return ListTileThemeData(
      tileColor: tileColor,
      iconColor: iconColor,
      textColor: textColor,
      style: ListTileStyle.drawer,
    );
  }
}