import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import 'subject_selection_screen.dart';
import 'live_quiz/live_quiz_entry_screen.dart';
import '../widgets/custom_drawer.dart';

class HomeSelectionScreen extends StatefulWidget {
  const HomeSelectionScreen({super.key});

  @override
  State<HomeSelectionScreen> createState() => _HomeSelectionScreenState();
}

class _HomeSelectionScreenState extends State<HomeSelectionScreen> {

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String displayName = user?.userMetadata?['full_name'] ??
                               user?.userMetadata?['username'] ?? 'Student';

    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Tailwind.slate800),
        title: const Text(
          'Arivora',
          style: TextStyle(fontWeight: FontWeight.bold, color: Tailwind.slate800)
        ),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Text(
                "Hello, $displayName! 👋",
                style: const TextStyle(
                  color: Tailwind.slate800,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Big ideas start with a curious question. Let’s explore!",
                style: TextStyle(
                  color: Tailwind.slate500,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Menu Selection Cards
              _MenuOptionCard(
                title: "Tuition",
                subtitle: "Explore Classes 6–12, ask Preethi about available textbooks, and review past chats.",
                icon: Icons.school_rounded,
                gradientColors: const [Color(0xFFE4DDFC), Color(0xFFF0E9FF)],
                iconBgColor: Tailwind.indigo100,
                iconColor: Tailwind.indigo600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubjectSelectionScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              _MenuOptionCard(
                title: "Quiz Game",
                subtitle: "Join a live classroom quiz with a code or create your own custom quiz.",
                icon: Icons.sports_esports_rounded,
                gradientColors: const [Color(0xFFD8F1E6), Color(0xFFEAF8F1)],
                iconBgColor: const Color(0xFFBDE4D2),
                iconColor: Tailwind.indigo600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LiveQuizEntryScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              _MenuOptionCard(
                title: "Interactive Simulations",
                subtitle: "Coming soon",
                icon: Icons.lock_outline_rounded,
                gradientColors: const [Color(0xFFFFE1DF), Color(0xFFFFEFEB)],
                iconBgColor: const Color(0xFFFFF0D5),
                iconColor: Tailwind.amber600,
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _MenuOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_MenuOptionCard> createState() => _MenuOptionCardState();
}

class _MenuOptionCardState extends State<_MenuOptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.onTap == null ? null : (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.gradientColors,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: _isHovered ? Tailwind.indigo400 : Colors.transparent),
              borderRadius: Tailwind.rounded2Xl,
              boxShadow: Tailwind.shadowSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 28
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Tailwind.slate800,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Tailwind.slate500,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  widget.onTap == null ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                  color: Tailwind.slate500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
