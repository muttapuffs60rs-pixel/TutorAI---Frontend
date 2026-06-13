import 'package:flutter/material.dart';
import '../../theme/tailwind_theme.dart';
import 'teacher_create_quiz_screen.dart';
import 'student_join_screen.dart';

class LiveQuizEntryScreen extends StatelessWidget {
  const LiveQuizEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        elevation: 0,
        title: const Text('Live Quiz 🎮', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Tailwind.slate800),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Hero banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: Tailwind.rounded3Xl,
                  boxShadow: Tailwind.shadowLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.quiz_rounded, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Live Classroom Quiz', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Real-time quizzes with live leaderboards. Engage your class like never before!',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CHOOSE YOUR ROLE',
                style: TextStyle(color: Tailwind.slate400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.school_rounded,
                title: "I'm a Teacher",
                subtitle: "Create a quiz, invite students with a code",
                color: const Color(0xFF4F46E5),
                lightColor: const Color(0xFFEEF2FF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherCreateQuizScreen())),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.person_rounded,
                title: "I'm a Student",
                subtitle: "Join a live quiz with a 6-digit code",
                color: const Color(0xFF059669),
                lightColor: const Color(0xFFECFDF5),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentJoinScreen())),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Tailwind.amber50, borderRadius: Tailwind.roundedXl, border: Border.all(color: Tailwind.amber200)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Tailwind.amber600, size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Both teacher and students must be logged in to participate.',
                        style: TextStyle(color: Tailwind.amber700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color lightColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.lightColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Tailwind.white,
          borderRadius: Tailwind.rounded2Xl,
          border: Border.all(color: Tailwind.slate100),
          boxShadow: Tailwind.shadowMd,
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Tailwind.slate500, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
