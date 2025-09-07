import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ckb.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ckb'),
    Locale('en'),
    Locale('ku'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'BUY X'**
  String get appTitle;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Explore tab label
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Auctions tab label
  ///
  /// In en, this message translates to:
  /// **'Auctions'**
  String get auctions;

  /// Chats tab label
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// My orders menu item
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// Notifications menu item
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Become vendor menu item
  ///
  /// In en, this message translates to:
  /// **'Become Vendor'**
  String get becomeVendor;

  /// Manage drivers menu item
  ///
  /// In en, this message translates to:
  /// **'Manage Drivers'**
  String get manageDrivers;

  /// Sold auctions menu item
  ///
  /// In en, this message translates to:
  /// **'Sold Auctions'**
  String get soldAuctions;

  /// Blocked users menu item
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// Edit profile menu item
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No data message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No network connection message
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noNetwork;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Bid button text
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get bid;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Time left label for auctions
  ///
  /// In en, this message translates to:
  /// **'Time Left'**
  String get timeLeft;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// Winner label
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// Current bid label
  ///
  /// In en, this message translates to:
  /// **'Current Bid'**
  String get currentBid;

  /// Place bid button text
  ///
  /// In en, this message translates to:
  /// **'Place Bid'**
  String get placeBid;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// Kurdish Sorani language option
  ///
  /// In en, this message translates to:
  /// **'کوردی سۆرانی'**
  String get kurdishSorani;

  /// Kurdish Badini language option
  ///
  /// In en, this message translates to:
  /// **'کوردی بادینی'**
  String get kurdishBadini;

  /// Vendor role text
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// Driver role text
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// User role text
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// All tab label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Sold navigation label
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// Favorites tab label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Watchlist tab label
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlist;

  /// Message when no active auctions
  ///
  /// In en, this message translates to:
  /// **'No active auctions'**
  String get noActiveAuctions;

  /// Message when nothing sold yet
  ///
  /// In en, this message translates to:
  /// **'Nothing sold yet'**
  String get nothingSoldYet;

  /// Message when no participation in auctions
  ///
  /// In en, this message translates to:
  /// **'No participation in any auction'**
  String get noParticipation;

  /// Message when watchlist is empty
  ///
  /// In en, this message translates to:
  /// **'Watchlist is empty'**
  String get emptyWatchlist;

  /// Help menu item
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Welcome greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// Welcome back greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// Login prompt text
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginToContinue;

  /// Email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// Password field prompt
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// Login error message
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get incorrectEmailOrPassword;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again.'**
  String get errorOccurred;

  /// Registration prompt
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started!'**
  String get registerToStart;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Name validation message
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Phone validation message
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be empty'**
  String get phoneCannotBeEmpty;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address (City)'**
  String get address;

  /// Address validation message
  ///
  /// In en, this message translates to:
  /// **'Address cannot be empty'**
  String get addressCannotBeEmpty;

  /// Password length validation
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// Password confirmation validation
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Account verification title
  ///
  /// In en, this message translates to:
  /// **'Verify your account'**
  String get verifyAccount;

  /// Create account title
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Or connector text
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Registration prompt question
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Create account link text
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// Send OTP button text
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// OTP form title
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// OTP instruction text
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code has been sent to your phone number:'**
  String get sixDigitCodeSent;

  /// OTP validation message
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 digits'**
  String get codeMustBeSixDigits;

  /// Final registration button
  ///
  /// In en, this message translates to:
  /// **'Verify and Register'**
  String get verifyAndRegister;

  /// Resend OTP button
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Resending OTP message
  ///
  /// In en, this message translates to:
  /// **'Resending code...'**
  String get resendingCode;

  /// Login link prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Login link text
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// Map navigation label
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Orders navigation label
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// Create navigation label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Driver dashboard title
  ///
  /// In en, this message translates to:
  /// **'Driver Dashboard'**
  String get driverDashboard;

  /// Today's statistics header
  ///
  /// In en, this message translates to:
  /// **'Today\'s Stats'**
  String get todayStats;

  /// Collected amount stat
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collectedAmount;

  /// Delivered today stat
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredToday;

  /// Pending deliveries stat
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingDeliveries;

  /// Performance stat
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// Today's tasks header
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasks;

  /// Tasks label
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No tasks message
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned for today.'**
  String get noTasks;

  /// Order for label
  ///
  /// In en, this message translates to:
  /// **'Order for'**
  String get orderFor;

  /// Unknown label
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Shipped status
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// Out for delivery status
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// Delivered status
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Processing status
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// Pending payment status
  ///
  /// In en, this message translates to:
  /// **'Pending Payment'**
  String get pendingPayment;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Successfully'**
  String get successfully;

  /// Updated message
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get updated;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'ckb', 'en', 'ku'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'ckb':
      return AppLocalizationsCkb();
    case 'en':
      return AppLocalizationsEn();
    case 'ku':
      return AppLocalizationsKu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
