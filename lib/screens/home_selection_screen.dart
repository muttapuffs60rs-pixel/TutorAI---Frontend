import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import 'subject_selection_screen.dart';
import 'live_quiz/live_quiz_entry_screen.dart';
import 'gamified_learning_screen.dart';

class HomeSelectionScreen extends StatefulWidget {
  const HomeSelectionScreen({super.key});

  @override
  State<HomeSelectionScreen> createState() => _HomeSelectionScreenState();
}

class _HomeSelectionScreenState extends State<HomeSelectionScreen> {
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Tailwind.white,
          shape: RoundedRectangleBorder(borderRadius: Tailwind.rounded2Xl),
          title: const Text(
            "Logout", 
            style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)
          ),
          content: const Text(
            "Are you sure you want to log out of your session?", 
            style: TextStyle(color: Tailwind.slate600)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Tailwind.slate500)),
            ),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: const Text(
                "Logout", 
                style: TextStyle(color: Tailwind.rose500, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );
  }

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
        title: const Text(
          'Tutor Preethi', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Tailwind.slate800)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Tailwind.slate500),
            onPressed: () => _showLogoutConfirmation(context),
          )
        ],
      ),
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
                "Enna panna poreenga iniku? Choose a learning mode to start.",
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
                subtitle: "Learn Class 10 & 12 subjects, ask doubts to Akka tutor, and review past chats.",
                icon: Icons.school_rounded,
                gradientColors: const [Color(0xFF4F46E5), Color(0xFF6366F1)], // Indigo Gradient
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
                gradientColors: const [Color(0xFF059669), Color(0xFF10B981)], // Emerald Gradient
                iconBgColor: Color(0xFFECFDF5), // Emerald light
                iconColor: Tailwind.emerald600,
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
                subtitle: "Play gamified physics simulations and learn through interactive experiences.",
                icon: Icons.science_rounded,
                gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)], // Amber Gradient
                iconBgColor: const Color(0xFFFEF3C7), // Amber light
                iconColor: Tailwind.amber600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GamifiedLearningScreen()),
                  );
                },
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
  final VoidCallback onTap;

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
      onEnter: (_) => setState(() => _isHovered = true),
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
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: Tailwind.rounded2Xl,
              boxShadow: _isHovered ? Tailwind.shadowLg : Tailwind.shadowMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon, 
                    color: Colors.white, 
                    size: 32
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
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
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

