// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/localization_service.dart';
import '../utils/ios26_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? darkBackground : lightBackground,
      appBar: AppBar(
        title: Text(
          LocalizationService.getString(context, (l10n) => l10n.settings, 'Settings'),
        ),
        backgroundColor: isDark ? darkBackground : lightBackground,
        foregroundColor: isDark ? darkPrimaryText : lightPrimaryText,
        elevation: 0,
      ),
      body: Container(
        color: isDark ? darkBackground : lightBackground,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            // Theme Settings
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? darkSurface : lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? darkSeparator : lightSeparator,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      LocalizationService.getString(context, (l10n) => l10n.theme, 'Theme'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? darkPrimaryText : lightPrimaryText,
                      ),
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: isDark ? darkSeparator : lightSeparator,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildThemeOption(
                    title: LocalizationService.getString(context, (l10n) => l10n.light, 'Light'),
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: isDark ? darkSeparator : lightSeparator,
                    indent: 56,
                    endIndent: 16,
                  ),
                  _buildThemeOption(
                    title: LocalizationService.getString(context, (l10n) => l10n.dark, 'Dark'),
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    isDark: isDark,
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: isDark ? darkSeparator : lightSeparator,
                    indent: 56,
                    endIndent: 16,
                  ),
                  _buildThemeOption(
                    title: LocalizationService.getString(context, (l10n) => l10n.system, 'System'),
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            
            // Design Style Settings
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? darkSurface : lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? darkSeparator : lightSeparator,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      LocalizationService.getString(context, (l10n) => l10n.designStyle, 'Design Style'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? darkPrimaryText : lightPrimaryText,
                      ),
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: isDark ? darkSeparator : lightSeparator,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDesignStyleOption(
                    title: 'iOS 26 Style',
                    subtitle: LocalizationService.getString(context, (l10n) => l10n.ios26StyleDescription, 'Use iOS 26 design language'),
                    isSelected: themeProvider.isIOS26Style,
                    onChanged: (value) => themeProvider.setIOS26Style(value),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            
            // Additional Settings
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? darkSurface : lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? darkSeparator : lightSeparator,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      LocalizationService.getString(context, (l10n) => l10n.additionalSettings, 'Additional Settings'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? darkPrimaryText : lightPrimaryText,
                      ),
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: isDark ? darkSeparator : lightSeparator,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildSettingOption(
                    icon: Icons.language_outlined,
                    title: LocalizationService.getString(context, (l10n) => l10n.language, 'Language'),
                    subtitle: LocalizationService.getString(context, (l10n) => l10n.changeAppLanguage, 'Change the app language'),
                    onTap: () {
                      // Navigate to language selection
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: isDark ? darkSeparator : lightSeparator,
                    indent: 56,
                    endIndent: 16,
                  ),
                  _buildSettingOption(
                    icon: Icons.notifications_outlined,
                    title: LocalizationService.getString(context, (l10n) => l10n.notifications, 'Notifications'),
                    subtitle: LocalizationService.getString(context, (l10n) => l10n.notificationSettings, 'Manage notification preferences'),
                    onTap: () {
                      // Navigate to notification settings
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? darkPrimaryText : lightPrimaryText,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDesignStyleOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? darkPrimaryText : lightPrimaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: isDark ? darkSecondaryText : lightSecondaryText,
        ),
      ),
      trailing: Switch(
        value: isSelected,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? darkPrimaryText : lightPrimaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: isDark ? darkSecondaryText : lightSecondaryText,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? darkSystemGray : lightSystemGray,
      ),
      onTap: onTap,
    );
  }
}