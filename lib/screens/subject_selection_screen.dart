import 'package:flutter/material.dart';
import '../main.dart'; 
import '../theme/tailwind_theme.dart';
import 'chat_screen.dart';

class SubjectSelectionScreen extends StatelessWidget {
  const SubjectSelectionScreen({super.key});

  final List<Map<String, dynamic>> subjects = const [
    {'name': 'Science', 'icon': Icons.science, 'color': Tailwind.emerald500},
    {'name': 'Maths', 'icon': Icons.calculate, 'color': Tailwind.indigo500},
    {'name': 'Social', 'icon': Icons.public, 'color': Tailwind.amber500},
    {'name': 'English', 'icon': Icons.language, 'color': Tailwind.rose500},
  ];

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Tailwind.white,
          shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
          title: const Text("Logout", style: TextStyle(color: Tailwind.slate800)),
          content: const Text("Are you sure you want to log out?", style: TextStyle(color: Tailwind.slate600)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Tailwind.slate500)),
            ),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout", style: TextStyle(color: Tailwind.rose500, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        elevation: 0,
        title: const Text('Tutor Preethi', style: TextStyle(fontWeight: FontWeight.bold, color: Tailwind.slate800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Tailwind.slate500),
            onPressed: () => _showLogoutConfirmation(context),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Vanakkam! 👋",
                      style: TextStyle(color: Tailwind.slate800, fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Iniku enna subject padikalam?",
                      style: TextStyle(color: Tailwind.slate500, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + (index * 100)), // Staggered delay
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(initialSubject: subject['name']),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Tailwind.white,
                            borderRadius: Tailwind.rounded2Xl,
                            boxShadow: Tailwind.shadowMd,
                            border: Border.all(color: Tailwind.slate100),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: subject['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(subject['icon'], size: 40, color: subject['color']),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                subject['name'],
                                style: const TextStyle(color: Tailwind.slate800, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
