import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/tailwind_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Automatically trigger navigation flow after a 3-second delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth_gate');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50, // Lightweight clean background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean shadow wrapper for the logo
                Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Tailwind.white,
                    borderRadius: Tailwind.rounded2Xl,
                    boxShadow: Tailwind.shadowLg,
                  ),
                  child: ClipRRect(
                    borderRadius: Tailwind.rounded2Xl,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.blur_on_rounded,
                          size: 72,
                          color: Tailwind.indigo500,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Company Name branding Typography
                const Text(
                  'AuxiumSoft',
                  style: TextStyle(
                    color: Tailwind.slate800,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Architecting the Digital Future',
                    style: TextStyle(
                    color: Tailwind.slate500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}