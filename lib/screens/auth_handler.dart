// lib/screens/auth_handler.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import './login_screen.dart';
import './main_screen.dart';
import './splash_screen.dart';

class AuthHandler extends StatefulWidget {
  const AuthHandler({super.key});

  @override
  State<AuthHandler> createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // ===== لۆجیکی سەرەکی بێ پچڕان لێرەدایە =====
    // 1. چاوەڕێی هەردوو کارەکە بکە: جووڵە و پشکنینی لۆگین
    final results = await Future.wait([
      // چاوەڕێی ماوەیەکی کەمتر لە جووڵەکە دەکەین بۆ گواستنەوەی نەرمتر
      Future.delayed(const Duration(milliseconds: 2500)), 
      authProvider.tryAutoLogin(),
    ]);

    final bool isLoggedIn = results[1];

    if (mounted) {
      Navigator.of(context).pushReplacement(
        // بەکارهێنانی PageRouteBuilder بۆ گواستنەوەی Fade
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              isLoggedIn ? const MainScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // هەمیشە SplashScreen پیشان دەدەین تا _initializeApp تەواو دەبێت
    return const SplashScreen();
  }
}