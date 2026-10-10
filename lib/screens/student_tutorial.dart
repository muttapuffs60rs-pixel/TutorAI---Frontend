import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tailwind_theme.dart';
import '../widgets/learning_mascot.dart';

class StudentTutorial extends StatefulWidget {
  final VoidCallback? onClose;
  const StudentTutorial({super.key, this.onClose});

  static String storageKey(String userId) => 'student_tutorial_v2_$userId';

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

class _StudentTutorialState extends State<StudentTutorial> {
  int step = 0;
  static const steps = [
    (
      'Welcome to Arivora!',
      'Your learning journey starts here. Take a quick tour to find your subjects, ask questions, and practise what you learn.',
      Icons.waving_hand_outlined,
    ),
    (
      'Find your subject',
      'On Home, tap Start learning or Tuition. Select your board first, then your class, then a subject. Use Search subjects to find one quickly.',
      Icons.auto_stories_outlined,
    ),
    (
      'Ask Preethi a question',
      'Type your question or tap the microphone to speak in Tamil or English. Review and add the text, then tap Send. You can also attach a picture of a question. Use the subject selector at the top to change your class or subject.',
      Icons.chat_bubble_outline,
    ),
    (
      'Join your live classroom',
      'Choose Live classroom on Home, then I’m a Student. Enter the 6-digit code from your teacher to join the quiz and answer questions with your class.',
      Icons.emoji_events_outlined,
    ),
    (
      'Find chats and usage',
      'Open the menu at the top left to revisit Recent chats or check your token usage and remaining balance. Upgrade Plan shows the available plans.',
      Icons.menu,
    ),
    (
      'You’re ready to explore',
      'Start with a subject you’re curious about. You can replay this tour anytime from Student tutorial in the menu.',
      Icons.explore_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = steps[step];
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Step ${step + 1} of ${steps.length}',
                      style: const TextStyle(color: Tailwind.slate600),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        (widget.onClose ?? () => Navigator.pop(context))(),
                    child: const Text('Skip tour'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: step == 0 || step == steps.length - 1
                    ? const LearningMascot(size: 100)
                    : Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Tailwind.pastels[step % 4],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.$3,
                          size: 48,
                          color: Tailwind.slate800,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Tailwind.slate800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Tailwind.slate700,
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: (step + 1) / steps.length,
                color: Tailwind.indigo600,
                backgroundColor: Tailwind.indigo100,
                semanticsLabel: 'Tour progress',
              ),
              const SizedBox(height: 20),
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
                    onPressed: () {
                      if (step == steps.length - 1) {
                        (widget.onClose ?? () => Navigator.pop(context))();
                      } else {
                        setState(() => step++);
                      }
                    },
                    child: Text(
                      step == steps.length - 1 ? 'Let’s learn' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
