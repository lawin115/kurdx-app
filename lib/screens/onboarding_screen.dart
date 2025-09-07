import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './auth_handler.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthHandler()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 رەنگەکانی برند
    const Color logoBlue = Color(0xFF2196F3);
    const Color logoGreen = Color(0xFF4CAF50);
    const Color accent = Color.fromARGB(255, 255, 255, 255);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyTextStyle: TextStyle(fontSize: 18, color: Colors.white70),
      imagePadding: EdgeInsets.only(top: 40, bottom: 20),
      pageColor: Colors.transparent,
    );

    Widget buildIcon(IconData icon, String emoji) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [logoBlue.withOpacity(0.9), logoGreen.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Icon(icon, size: 60, color: Colors.white),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [logoBlue, logoGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: IntroductionScreen(
        globalBackgroundColor: Colors.transparent,
        pages: [
          PageViewModel(
            title: "👋 بەخێربێیت بۆ BUY X",
            body: "شوێنێکی نوێ بۆ دۆزینەوەی مەزادی نایاب و بەشداریکردن لە شوێنەکەت.",
            image: buildIcon(Icons.gavel, "⚖️"),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "📈 نرخ زیاد بکە و ببە براوە",
            body: "چاودێری مەزادەکان بکە، نرخ زیاد بکە و بە ئەستێرەی بازار ببە.",
            image: buildIcon(Icons.trending_up, "💹"),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "🔒 ئاسان و سەلامەت",
            body: "معامەتی سەلامەت و بە پشت‌پەنا بدەستبێنە بە بەرنامەکەمان.",
            image: buildIcon(Icons.security, "🛡️"),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onIntroEnd(context),
        onSkip: () => _onIntroEnd(context),
        showSkipButton: true,
        skip: const Text("پەڕین", style: TextStyle(color: Colors.white)),
        next: const Icon(Icons.arrow_forward, color: Colors.white),
        done: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(206, 38, 255, 128),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            "دەستپێبکە",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        dotsDecorator: DotsDecorator(
          size: const Size(10, 10),
          color: Colors.white30,
          activeColor: accent,
          activeSize: const Size(22, 10),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        curve: Curves.easeInOut,
      ),
    );
  }
}
