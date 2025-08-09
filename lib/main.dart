// lib/main.dart

import 'package:flutter/material.dart';
import 'package:kurdpoint/providers/notification_provider.dart';
import 'package:kurdpoint/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import './providers/auth_provider.dart';
import './providers/theme_provider.dart';
import './screens/login_screen.dart';
import './screens/main_screen.dart';
import './screens/splash_screen.dart';
import './screens/onboarding_screen.dart';
import './firebase_options.dart';
import './screens/auth_handler.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => NotificationProvider()),
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

    // ===== دیزاینی نوێ لێرە پێناسە کراوە =====
    const Color primaryDarkBlue = Color(0xFF1A2035);
    const Color accentGold = Color(0xFFFFA726); // زەردێکی جوانتر
    const Color darkSurface = Color(0xFF2A314A);

    return MaterialApp(
      title: 'Kurd Bids',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      
      themeMode: themeProvider.themeMode,
      
      // --- تیمی ڕووناک (Light Mode) ---
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        primaryColor: primaryDarkBlue,
        colorScheme: const ColorScheme.light(
          primary: primaryDarkBlue,
          secondary: accentGold,
          background: Color.fromARGB(255, 255, 255, 255),
          surface: Colors.white,
          surfaceDim: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
            shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDarkBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryDarkBlue,
          unselectedItemColor: Colors.grey[400],
        ),
      ),

      // --- تیمی تاریک (Dark Mode) ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primaryDarkBlue,
        primaryColor: accentGold,
        colorScheme: const ColorScheme.dark(
          primary: accentGold,
          secondary: primaryDarkBlue,
          background: primaryDarkBlue,
          surface: darkSurface,
          surfaceDim: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
            shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          color: darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: accentGold,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: darkSurface.withOpacity(0.8),
        ),
      ),

     home: seenOnboarding 
        ? const AuthHandler() // ئەگەر پێشتر بینیویەتی، بچۆ بۆ پشکنینی لۆگین
        : const OnboardingScreen(), // ئەگەرنا، Onboarding پیشان بدە
    );
  }
}

// ویجێتێکی نوێ بۆ پاکڕاگرتنی build method
class AuthHandler extends StatelessWidget {
  const AuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        if (auth.isLoggedIn) {
          return const MainScreen();
        }
        return FutureBuilder(
          future: auth.tryAutoLogin(),
          builder: (ctx, authResultSnapshot) {
            if (authResultSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}