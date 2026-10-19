import '../widgets/referral_invite_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'board_selection_screen.dart';
import 'student_tutorial.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/learning_mascot.dart';
import '../widgets/opening_day_welcome_offer.dart';
import 'subject_selection_screen.dart';
import 'live_quiz/live_quiz_entry_screen.dart';
import 'student_profile_screen.dart';

class HomeSelectionScreen extends StatefulWidget {
  const HomeSelectionScreen({super.key});

  @override
  State<HomeSelectionScreen> createState() => _HomeSelectionScreenState();
}

class _HomeSelectionScreenState extends State<HomeSelectionScreen> {
  bool _showIntroduction = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _introduce());
  }

  Future<void> _introduce() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null ||
        savedBoard(supabase.auth.currentUser?.userMetadata) == null) {
      return;
    }
    try {
      final needed = await StudentTutorial.needsIntroduction(userId);
      if (!mounted || !needed || supabase.auth.currentUser?.id != userId) {
        return;
      }
      setState(() => _showIntroduction = true);
    } catch (error) {
      debugPrint('Tutorial preference unavailable: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = savedBoard(supabase.auth.currentUser?.userMetadata);
    if (board == null) {
      return BoardSelectionScreen(
        onSave: (value) async {
          await supabase.auth.updateUser(
            UserAttributes(data: {'education_board': value}),
          );
          if (!mounted) return;
          setState(() {});
          await _introduce();
        },
      );
    }
    if (_showIntroduction) {
      return Scaffold(
        body: StudentTutorial(
          onClose: () {
            setState(() => _showIntroduction = false);
            final id = supabase.auth.currentUser?.id;
            if (id != null) StudentTutorial.remember(id);
          },
        ),
      );
    }
    final user = supabase.auth.currentUser;
    final name =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['username'] ??
        'Student';
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arivora'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'My profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Tailwind.indigo50,
                      borderRadius: Tailwind.roundedXl,
                      border: Border.all(color: Tailwind.indigo600, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STEP 1 · YOUR SCHOOL BOARD',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Tailwind.indigo600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose your board first',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Tailwind.slate800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your board determines the textbooks and lessons you study. Check it before choosing your class and subject.',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selected: ${boardNames[board]}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.school_outlined),
                          label: const Text('Choose / change board'),
                          onPressed: () => open(
                            BoardSelectionScreen(
                              changing: true,
                              initialBoard: board,
                              onSave: (selected) async {
                                await supabase.auth.updateUser(
                                  UserAttributes(
                                    data: {'education_board': selected},
                                  ),
                                );
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                                    open(SubjectSelectionScreen(board: board)),
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
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('How to use Arivora'),
                      subtitle: const Text(
                        'A quick guide to questions, practice and live classes',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => StudentTutorial.show(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 16),
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
                          ? 3
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
                            onTap: () =>
                                open(SubjectSelectionScreen(board: board)),
                          ),
                          _LearningCard(
                            width: width,
                            title: 'Quizzes',
                            subtitle: 'Practise alone or join your class',
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
                  const SizedBox(height: 20),
                  const ReferralInviteBanner(),
                  OpeningDayWelcomeOffer(
                    accountCreatedAt: DateTime.tryParse(user?.createdAt ?? ''),
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
