import 'package:flutter/material.dart';
import '../main.dart';
import '../constants.dart';
import '../theme/tailwind_theme.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/learning_mascot.dart';
import 'subject_selection_screen.dart';
import 'live_quiz/live_quiz_entry_screen.dart';
import 'quiz_setup_screen.dart';

class HomeSelectionScreen extends StatelessWidget {
  const HomeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final name =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['username'] ??
        'Student';
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: const Text('Arivora'), centerTitle: true),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Tailwind.pastels[1],
                      borderRadius: Tailwind.roundedXl,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $name!',
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Tailwind.slate800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'A little curiosity. A big discovery.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Tailwind.slate700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    open(const SubjectSelectionScreen()),
                                child: const Text('Start learning'),
                              ),
                            ],
                          ),
                        ),
                        const LearningMascot(size: 112),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Tailwind.sunshine,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Explore learning',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Tailwind.slate800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 750
                          ? 4
                          : constraints.maxWidth >= 330
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _LearningCard(
                            width: width,
                            title: 'Tuition',
                            subtitle: 'Ask, understand, explore',
                            icon: Icons.auto_stories_outlined,
                            color: Tailwind.pastels[0],
                            onTap: () => open(const SubjectSelectionScreen()),
                          ),
                          _LearningCard(
                            width: width,
                            title: 'Practice quizzes',
                            subtitle: 'Learn at your own pace',
                            icon: Icons.emoji_events_outlined,
                            color: Tailwind.pastels[1],
                            onTap: () => open(const QuizSetupScreen()),
                          ),
                          _LearningCard(
                            width: width,
                            title: 'Live classroom',
                            subtitle: 'Join a quiz together',
                            icon: Icons.school_outlined,
                            color: Tailwind.pastels[2],
                            onTap: () => open(const LiveQuizEntryScreen()),
                          ),
                          _LearningCard(
                            width: width,
                            title: 'Simulations',
                            subtitle: 'Coming soon',
                            icon: Icons.science_outlined,
                            color: Tailwind.pastels[3],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Explore your subjects',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Tailwind.slate800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Tailwind.slate200),
                      borderRadius: Tailwind.roundedXl,
                      boxShadow: Tailwind.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Classes 6–12',
                          style: TextStyle(
                            color: Tailwind.indigo600,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your textbooks. Your next discovery.',
                          style: TextStyle(
                            color: Tailwind.slate700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: supportedGrades
                              .map(
                                (grade) => OutlinedButton(
                                  onPressed: () => open(
                                    SubjectSelectionScreen(initialGrade: grade),
                                  ),
                                  child: Text('Class $grade'),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final double width;
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _LearningCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: Tailwind.slate800),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Tailwind.slate800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Tailwind.slate600),
              ),
              const SizedBox(height: 12),
              Icon(
                onTap == null ? Icons.lock_outline : Icons.arrow_forward,
                size: 19,
                color: Tailwind.slate800,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
