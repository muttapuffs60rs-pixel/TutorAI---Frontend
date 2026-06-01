import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger navigation flow after a 3-second delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth_gate');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF7B2CBF);

    return Scaffold(
      backgroundColor: themePurple, // Aligned with global background branding
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // INTEGRATED: Production brand asset framework with smooth layout limits
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback visual safety anchor if asset pathing misses during compiling
                    return const Icon(
                      Icons.blur_on_rounded,
                      size: 72,
                      color: Colors.amber,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Company Name branding Typography
            const Text(
              'AuxiumSoft',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Learning Ecosystem',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}