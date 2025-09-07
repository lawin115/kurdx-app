import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

/// A service to safely access localized strings with fallback support
class LocalizationService {
  static LocalizationService? _instance;
  static LocalizationService get instance => _instance ??= LocalizationService._();
  
  LocalizationService._();

  /// Safely get localized string with fallback
  static String getString(
    BuildContext context, 
    String Function(AppLocalizations) getter, 
    String fallback
  ) {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        return getter(l10n);
      }
    } catch (e) {
      debugPrint('Localization error: $e');
    }
    return fallback;
  }

  /// Get app title safely
  static String getAppTitle(BuildContext context) => 
      getString(context, (l10n) => l10n.appTitle, 'BUY X');

  /// Get home safely
  static String getHome(BuildContext context) => 
      getString(context, (l10n) => l10n.home, 'Home');

  /// Get explore safely
  static String getExplore(BuildContext context) => 
      getString(context, (l10n) => l10n.explore, 'Explore');

  /// Get auctions safely
  static String getAuctions(BuildContext context) => 
      getString(context, (l10n) => l10n.auctions, 'Auctions');

  /// Get chats safely
  static String getChats(BuildContext context) => 
      getString(context, (l10n) => l10n.chats, 'Chats');

  /// Get profile safely
  static String getProfile(BuildContext context) => 
      getString(context, (l10n) => l10n.profile, 'Profile');

  /// Get login safely
  static String getLogin(BuildContext context) => 
      getString(context, (l10n) => l10n.login, 'Login');

  /// Get logout safely
  static String getLogout(BuildContext context) => 
      getString(context, (l10n) => l10n.logout, 'Logout');

  /// Get register safely
  static String getRegister(BuildContext context) => 
      getString(context, (l10n) => l10n.register, 'Register');

  /// Get email safely
  static String getEmail(BuildContext context) => 
      getString(context, (l10n) => l10n.email, 'Email');

  /// Get password safely
  static String getPassword(BuildContext context) => 
      getString(context, (l10n) => l10n.password, 'Password');

  /// Get confirm password safely
  static String getConfirmPassword(BuildContext context) => 
      getString(context, (l10n) => l10n.confirmPassword, 'Confirm Password');

  /// Get forgot password safely
  static String getForgotPassword(BuildContext context) => 
      getString(context, (l10n) => l10n.forgotPassword, 'Forgot Password?');

  /// Get name safely
  static String getName(BuildContext context) => 
      getString(context, (l10n) => l10n.name, 'Name');

  /// Get phone safely
  static String getPhone(BuildContext context) => 
      getString(context, (l10n) => l10n.phone, 'Phone');

  /// Get settings safely
  static String getSettings(BuildContext context) => 
      getString(context, (l10n) => l10n.settings, 'Settings');

  /// Get language safely
  static String getLanguage(BuildContext context) => 
      getString(context, (l10n) => l10n.language, 'Language');

  /// Get theme safely
  static String getTheme(BuildContext context) => 
      getString(context, (l10n) => l10n.theme, 'Theme');

  /// Get save safely
  static String getSave(BuildContext context) => 
      getString(context, (l10n) => l10n.save, 'Save');

  /// Get cancel safely
  static String getCancel(BuildContext context) => 
      getString(context, (l10n) => l10n.cancel, 'Cancel');

  /// Get search safely
  static String getSearch(BuildContext context) => 
      getString(context, (l10n) => l10n.search, 'Search');

  /// Get loading safely
  static String getLoading(BuildContext context) => 
      getString(context, (l10n) => l10n.loading, 'Loading...');

  /// Get error safely
  static String getError(BuildContext context) => 
      getString(context, (l10n) => l10n.error, 'Error');

  /// Get retry safely
  static String getRetry(BuildContext context) => 
      getString(context, (l10n) => l10n.retry, 'Retry');

  /// Get confirm safely
  static String getConfirm(BuildContext context) => 
      getString(context, (l10n) => l10n.confirm, 'Confirm');

  /// Get yes safely
  static String getYes(BuildContext context) => 
      getString(context, (l10n) => l10n.yes, 'Yes');

  /// Get no safely
  static String getNo(BuildContext context) => 
      getString(context, (l10n) => l10n.no, 'No');

  /// Get ok safely
  static String getOk(BuildContext context) => 
      getString(context, (l10n) => l10n.ok, 'OK');

  /// Get close safely
  static String getClose(BuildContext context) => 
      getString(context, (l10n) => l10n.close, 'Close');

  /// Get vendor safely
  static String getVendor(BuildContext context) => 
      getString(context, (l10n) => l10n.vendor, 'Vendor');

  /// Get driver safely
  static String getDriver(BuildContext context) => 
      getString(context, (l10n) => l10n.driver, 'Driver');

  /// Get user safely
  static String getUser(BuildContext context) => 
      getString(context, (l10n) => l10n.user, 'User');

  /// Get select language safely
  static String getSelectLanguage(BuildContext context) => 
      getString(context, (l10n) => l10n.selectLanguage, 'Select Language');

  /// Get edit profile safely
  static String getEditProfile(BuildContext context) => 
      getString(context, (l10n) => l10n.editProfile, 'Edit Profile');

  /// Get blocked users safely
  static String getBlockedUsers(BuildContext context) => 
      getString(context, (l10n) => l10n.blockedUsers, 'Blocked Users');

  /// Get notifications safely
  static String getNotifications(BuildContext context) => 
      getString(context, (l10n) => l10n.notifications, 'Notifications');

  /// Get help safely
  static String getHelp(BuildContext context) => 
      getString(context, (l10n) => l10n.help, 'Help');

  /// Get welcome safely
  static String getWelcome(BuildContext context) => 
      getString(context, (l10n) => l10n.welcome, 'Welcome!');

  /// Get welcome back safely
  static String getWelcomeBack(BuildContext context) => 
      getString(context, (l10n) => l10n.welcomeBack, 'Welcome back!');

  // Additional commonly used methods that might be missing from ARB files
  static String getMap(BuildContext context) => 
      getString(context, (l10n) => l10n.map, 'Map');

  static String getOrders(BuildContext context) => 
      getString(context, (l10n) => l10n.orders, 'Orders');

  static String getCreate(BuildContext context) => 
      getString(context, (l10n) => l10n.create, 'Create');

  static String getDashboard(BuildContext context) => 
      getString(context, (l10n) => l10n.dashboard, 'Dashboard');

  static String getEnterPassword(BuildContext context) => 
      getString(context, (l10n) => l10n.enterPassword, 'Enter password');

  static String getLoginToContinue(BuildContext context) => 
      getString(context, (l10n) => l10n.loginToContinue, 'Login to continue');

  static String getEnterValidEmail(BuildContext context) => 
      getString(context, (l10n) => l10n.enterValidEmail, 'Please enter a valid email');

  static String getIncorrectEmailOrPassword(BuildContext context) => 
      getString(context, (l10n) => l10n.incorrectEmailOrPassword, 'Incorrect email or password.');

  static String getErrorOccurred(BuildContext context) => 
      getString(context, (l10n) => l10n.errorOccurred, 'An error occurred, please try again.');

  /// Safe role text getter
  static String getRoleText(BuildContext context, String? role) {
    switch (role) {
      case 'vendor':
        return getVendor(context);
      case 'driver':
        return getDriver(context);
      default:
        return getUser(context);
    }
  }
}