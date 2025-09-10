import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kurdpoint/providers/notification_provider.dart';
import 'package:kurdpoint/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import './providers/auth_provider.dart';
import './providers/theme_provider.dart';
import './providers/language_provider.dart';
import './providers/data_cache_provider.dart';
import './screens/login_screen.dart';
import './screens/main_screen.dart';
import './screens/fast_splash_screen.dart';
import './screens/onboarding_screen.dart';
import './firebase_options.dart';
import './screens/auth_handler.dart';
import './generated/l10n/app_localizations.dart';
import './services/kurdish_localizations_delegate.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("Handling a background message: ${message.messageId}");
  } catch (e) {
    print("Firebase initialization error in background handler: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // فول‌سکرین بکە
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => LanguageProvider()),
        ChangeNotifierProvider(create: (ctx) => NotificationProvider()),
        ChangeNotifierProvider(create: (ctx) => DataCacheProvider()),
      ],
      child: MyApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    // 🌈 رەنگەکانی برند
    const Color logoBlue = Color(0xFF2196F3);
    const Color logoGreen = Color(0xFF4CAF50);

    return MaterialApp(
      title: 'BUY X',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      themeMode: themeProvider.themeMode,
      
      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        KurdishMaterialLocalizationsDelegate(),
        KurdishCupertinoLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
        Locale('ckb'), // Kurdish Sorani
        Locale('ku'), // Kurdish Badini
      ],
      locale: languageProvider.currentLocale,

      // 🔆 Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: logoBlue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: logoBlue,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: logoBlue,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: logoBlue,
          secondary: logoGreen,
          background: Colors.white,
          surface: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: logoBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: logoBlue,
          unselectedItemColor: Colors.grey[500],
        ),
      ),

      // 🌙 Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: logoGreen,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF121212),
          foregroundColor: logoGreen,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: logoGreen,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: logoGreen,
          secondary: logoBlue,
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: logoGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: logoGreen,
          unselectedItemColor: Colors.grey[400],
        ),
      ),

      home: NetworkGuard(
        child: seenOnboarding
            ? const AuthHandler()
            : const FastSplashScreen(),
      ),
    );
  }
}

/// ویجێت بۆ چاودێری نەتوۆرک
class NetworkGuard extends StatefulWidget {
  final Widget child;
  const NetworkGuard({super.key, required this.child});

  @override
  State<NetworkGuard> createState() => _NetworkGuardState();
}

class _NetworkGuardState extends State<NetworkGuard> {
  late StreamSubscription subscription;
  bool hasConnection = true;

  @override
  void initState() {
    super.initState();
    subscription = Connectivity().onConnectivityChanged.listen((results) {
      // results = List<ConnectivityResult>
      setState(() {
        hasConnection = results.isNotEmpty &&
            results.any((result) => result != ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasConnection) {
      return const NoNetworkScreen();
    }
    return widget.child;
  }
}


/// پەیجی "نەتوۆرک نییە"
class NoNetworkScreen extends StatelessWidget {
  const NoNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            const Text(
              "❌ نەتوۆرک نییە",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              "تکایە پەیوەستبکە بە ئینتەرنێت\nدووبارە هەوڵبدەوە",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                var result = await Connectivity().checkConnectivity();
                if (result != ConnectivityResult.none) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const FastSplashScreen()),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text("دووبارە هەوڵبدە"),
            )
          ],
        ),
      ),
    );
  }
}
