// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './auth_handler.dart'; // لاپەڕەی پشکنینی لۆگین

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // ===== تەنها یەک функцIAی کامڵ بۆ کۆتایی هاتن =====
  // ئەم функцIAیە هەم بۆ "Done" و هەم بۆ "Skip" کاردەکات
  Future<void> _onIntroEnd(BuildContext context) async {
    try {
      // 1. پاشەکەوتکردنی ئەوەی کە بەکارهێنەر لاپەڕەکەی بینیوە
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      // 2. گواستنەوەی بەکارهێنەر بۆ لاپەڕەی داهاتوو
      //    بەکارهێنانی pushReplacement بۆ ئەوەی نەتوانێت بگەڕێتەوە بۆ Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthHandler()),
      );
    } catch (e) {
      print("Error saving onboarding status: $e");
      // حاڵەتێکی یەدەگ ئەگەر هەڵەیەک ڕوویدا
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthHandler()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // دیزاینی لاپەڕەکان
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
      bodyTextStyle: TextStyle(fontSize: 19.0, color: Colors.white70),
      imagePadding: EdgeInsets.all(24),
      pageColor: Color(0xFF1A2035), // هەمان ڕەنگی شینی تۆخ
    );

    return IntroductionScreen(
      globalBackgroundColor: const Color(0xFF1A2035),
      pages: [
        PageViewModel(
          title: "بەخێربێیت بۆ Kurd Bids",
          body: "باشترین شوێن بۆ دۆزینەوەی مەزادی نایاب و بەشداریکردن تێیدا.",
          image: const Icon(Icons.gavel, size: 120, color: Color(0xFFFFA726)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "نرخ زیاد بکە و ببە براوە",
          body: "بە ئاسانی چاودێری مەزادەکان بکە و نرخەکانت زیاد بکە بۆ بردنەوە.",
          image: const Icon(Icons.trending_up, size: 120, color: Color(0xFFFFA726)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "ئاسان و سەلامەت",
          body: "ئێمە ئەزموونێکی سەلامەت و ئاسانت بۆ دابین دەکەین.",
          image: const Icon(Icons.security, size: 120, color: Color(0xFFFFA726)),
          decoration: pageDecoration,
        ),
      ],
      // کاتێک دوگمەی Done دادەگیرێت، ئەم функцIAیە بانگ دەکرێت
      onDone: () => _onIntroEnd(context),
      // کاتێک دوگمەی Skip دادەگیرێت، هەمان функцIA بانگ دەکرێت
      onSkip: () => _onIntroEnd(context),
      
      showSkipButton: true,
      skip: const Text("پەڕین", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      next: const Icon(Icons.arrow_forward, color: Colors.white),
      done: const Text("دەستپێبکە", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      
      // دیزاینی خاڵەکانی خوارەوە
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.white30,
        activeColor: Color(0xFFFFA726),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}