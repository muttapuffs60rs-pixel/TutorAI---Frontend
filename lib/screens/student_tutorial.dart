import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tailwind_theme.dart';

class StudentTutorial extends StatefulWidget {
  final VoidCallback? onClose;
  const StudentTutorial({super.key, this.onClose});

  // Show the improved guide once, including to students who saw the old tour.
  static String storageKey(String userId) => 'student_tutorial_v3_$userId';

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const StudentTutorial(),
  );

  static Future<bool> needsIntroduction(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(storageKey(userId)) ?? false);
  }

  static Future<void> remember(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey(userId), true);
  }

  @override
  State<StudentTutorial> createState() => _StudentTutorialState();
}

class _TourStep {
  final String title, summary, route, example, tip;
  final List<String> actions;
  final IconData icon;
  const _TourStep({
    required this.title,
    required this.summary,
    required this.route,
    required this.actions,
    required this.example,
    required this.tip,
    required this.icon,
  });
}

class _StudentTutorialState extends State<StudentTutorial> {
  int step = 0;
  static const steps = [
    _TourStep(
      title: 'Your first steps in Arivora',
      summary:
          'Learn where to go and what to tap. You can skip this guide and open it again whenever you need.',
      route: 'Home',
      actions: [
        'Tuition helps you understand a lesson or ask a question.',
        'Quizzes lets you practise alone or join your teacher’s class.',
      ],
      example:
          'Ask a question → understand the explanation → try a practice question.',
      tip:
          'Look for “How to use Arivora” on Home or in the menu to replay this guide.',
      icon: Icons.explore_outlined,
    ),
    _TourStep(
      title: 'Choose the right textbook',
      summary:
          'Start with your board, class and subject so your learning matches your course.',
      route: 'Home → Tuition → Class → Subject',
      actions: [
        'Check Board & curriculum on Home. Tap it if you need to change boards.',
        'Tap Tuition or Start learning. Select your class first, then your subject.',
      ],
      example: 'Tamil Nadu State Board · Class 6 · Science',
      tip:
          'You can change your class or subject using the selector at the top of a tutoring chat.',
      icon: Icons.auto_stories_outlined,
    ),
    _TourStep(
      title: 'Ask your first question',
      summary:
          'Be specific about what you want to understand. You can type, speak or attach a clear photo.',
      route: 'Tuition → Question box → Send',
      actions: [
        'Type a question, use the Tamil keyboard, or tap the microphone. Review spoken text before adding it to your message.',
        'For a photo, crop to the question. Add what you need help with, then tap Send.',
        'Want more help? Choose Hint, Short explanation or Full solution, then tap Send.',
      ],
      example:
          '“Explain evaporation with an everyday example.”\nFollow up: “How is boiling different?”',
      tip:
          'Ask one question at a time. Include the exercise number or question text when it matters.',
      icon: Icons.chat_bubble_outline,
    ),
    _TourStep(
      title: 'Practise at your own pace',
      summary: 'Solo practice needs no teacher, session code or timer.',
      route: 'Home → Quizzes → Practise alone',
      actions: [
        'Choose your class and subject. Enter a chapter name or topic, then choose how many questions to practise.',
        'Answer each question and read the explanation. At the end, review the questions you missed.',
      ],
      example:
          'Chapter or topic: Fractions\nStart with 3 questions for a short practice session.',
      tip:
          'Solo practice currently uses Tamil Nadu State Board textbooks for Classes 6–12. CBSE solo practice is not available yet.',
      icon: Icons.edit_note_outlined,
    ),
    _TourStep(
      title: 'Join a live classroom',
      summary:
          'A live quiz is different from solo practice: your teacher starts it and controls the questions.',
      route: 'Home → Quizzes → I’m a Student',
      actions: [
        'Enter the session code your teacher shares and check your name before tapping JOIN NOW.',
        'Wait for the teacher to start. Submit one answer to the current question and follow the next question when it appears.',
        'If you are hosting, choose I’m a Teacher instead, add your questions and share the generated code.',
      ],
      example:
          'Session PIN: enter your teacher’s code\nYour Name: the name your teacher will recognise',
      tip:
          'No code? Choose Practise alone. If a classroom code does not work, check it with your teacher.',
      icon: Icons.groups_outlined,
    ),
    _TourStep(
      title: 'Find your chats and balance',
      summary:
          'The menu keeps your recent learning and account information in one place.',
      route: 'Top-left menu',
      actions: [
        'Open Recent chats to revisit an explanation or continue a saved conversation.',
        'Check your plan and available balance in the menu. Open My profile for your credit history.',
        'Upgrade Plan explains the available plans. Contact support is there if you need help.',
      ],
      example:
          'Recent chats → reopen a lesson\nMy profile → check your credit history',
      tip:
          'If you reach a conversation limit, start a new chat from the menu. Your account’s available balance still applies.',
      icon: Icons.menu_book_outlined,
    ),
    _TourStep(
      title: 'Ready for your first lesson?',
      summary: 'Choose a subject you want to understand a little better today.',
      route: 'Home → Start learning',
      actions: [
        'Choose your class and subject.',
        'Ask one clear question and read the explanation.',
        'Practise the topic to check what you have learned.',
      ],
      example:
          'A good first question: “Explain this topic simply, then give me an example.”',
      tip:
          'Need a reminder later? Open How to use Arivora on Home or in the menu.',
      icon: Icons.school_outlined,
    ),
  ];

  void close() => (widget.onClose ?? () => Navigator.pop(context))();

  @override
  Widget build(BuildContext context) {
    final item = steps[step];
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Step ${step + 1} of ${steps.length}',
                      style: const TextStyle(
                        color: Tailwind.slate600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(onPressed: close, child: const Text('Skip tour')),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                key: ValueKey(step),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Tailwind.pastels[step % 4],
                        borderRadius: Tailwind.roundedMd,
                      ),
                      child: Icon(
                        item.icon,
                        size: 32,
                        color: Tailwind.slate800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Tailwind.slate800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.summary,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Tailwind.slate700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Tailwind.indigo50,
                        borderRadius: Tailwind.roundedMd,
                      ),
                      child: Text(
                        item.route,
                        style: const TextStyle(
                          color: Tailwind.slate800,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < item.actions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '${i + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Tailwind.indigo600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.actions[i],
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: Tailwind.slate800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Tailwind.pastels[(step + 1) % 4],
                        borderRadius: Tailwind.roundedMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXAMPLE',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                              color: Tailwind.slate700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.example,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: Tailwind.slate800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.tip,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Tailwind.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: (step + 1) / steps.length,
                    color: Tailwind.indigo600,
                    backgroundColor: Tailwind.indigo100,
                    semanticsLabel:
                        'Tour progress, step ${step + 1} of ${steps.length}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (step > 0)
                        OutlinedButton(
                          onPressed: () => setState(() => step--),
                          child: const Text('Back'),
                        ),
                      ElevatedButton(
                        onPressed: () => step == steps.length - 1
                            ? close()
                            : setState(() => step++),
                        child: Text(
                          step == steps.length - 1 ? 'Let’s learn' : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
