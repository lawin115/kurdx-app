import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kurdpoint/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster animation
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // Smoother, faster curve
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _controller.forward();
    
    // Navigate faster - total 1 second
    Timer(const Duration(milliseconds: 1000), _navigateToMain);
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200), // Faster transition
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: XLogoPainter(),
                    size: const Size(120, 120),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class XLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF1DA1F2), // Twitter/X blue
          Color(0xFF14A085), // Teal green
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create X shape centered properly
    final center = Offset(size.width / 2, size.height / 2 - 10); // Moved up slightly to account for dots
    final radius = size.width * 0.3;
    final strokeWidth = radius * 0.25;
    
    // First diagonal of X (top-left to bottom-right)
    path.moveTo(center.dx - radius, center.dy - radius);
    path.lineTo(center.dx - radius + strokeWidth, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy + radius - strokeWidth);
    path.lineTo(center.dx + radius, center.dy + radius);
    path.lineTo(center.dx + radius - strokeWidth, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy - radius + strokeWidth);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Second diagonal of X (top-right to bottom-left)
    final path2 = Path();
    path2.moveTo(center.dx + radius, center.dy - radius);
    path2.lineTo(center.dx + radius, center.dy - radius + strokeWidth);
    path2.lineTo(center.dx - radius + strokeWidth, center.dy + radius);
    path2.lineTo(center.dx - radius, center.dy + radius);
    path2.lineTo(center.dx - radius, center.dy + radius - strokeWidth);
    path2.lineTo(center.dx + radius - strokeWidth, center.dy - radius);
    path2.close();
    
    canvas.drawPath(path2, paint);
    
    // Add two dots at the bottom (perfectly centered)
    final dotPaint = Paint()
      ..color = const Color(0xFF14A085)
      ..style = PaintingStyle.fill;
    
    final dotRadius = radius * 0.12;
    final dotSpacing = radius * 0.8;
    final dotY = center.dy + radius * 1.2;
    
    // Left dot
    canvas.drawCircle(
      Offset(center.dx - dotSpacing / 2, dotY), 
      dotRadius, 
      dotPaint
    );
    
    // Right dot  
    canvas.drawCircle(
      Offset(center.dx + dotSpacing / 2, dotY), 
      dotRadius, 
      dotPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}