import 'package:flutter/material.dart';
import '../widgets/learning_mascot.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import '../constants.dart';
import '../widgets/grade_selector.dart';
import 'chat_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final int initialGrade;
  const SubjectSelectionScreen({super.key, this.initialGrade = 10});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  late int _selectedGrade = widget.initialGrade;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Tailwind.white,
          shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
          title: const Text(
            "Logout",
            style: TextStyle(color: Tailwind.slate800),
          ),
          content: const Text(
            "Are you sure you want to log out?",
            style: TextStyle(color: Tailwind.slate600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Tailwind.slate500),
              ),
            ),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: const Text(
                "Logout",
                style: TextStyle(
                  color: Tailwind.rose500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activeList = subjectsForGrade(_selectedGrade);
    if (_searchQuery.isNotEmpty) {
      activeList = activeList
          .where(
            (s) => s['name'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        elevation: 0,
        title: const Text(
          'Arivora',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Tailwind.slate800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Tailwind.slate500),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradeSelector(
                value: _selectedGrade,
                onChanged: (grade) => setState(() {
                  _selectedGrade = grade;
                  _searchController.clear();
                  _searchQuery = '';
                }),
              ),
              if (gradeContentNotice(_selectedGrade) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    gradeContentNotice(_selectedGrade)!,
                    style: const TextStyle(color: Tailwind.slate600),
                  ),
                ),
              const SizedBox(height: 24),

              const Row(
                children: [
                  Expanded(
                    child: Text(
                      "What will you discover today?",
                      style: TextStyle(
                        color: Tailwind.slate800,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  LearningMascot(size: 72),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Tailwind.white,
                  borderRadius: Tailwind.roundedXl,
                  boxShadow: Tailwind.shadowSm,
                  border: Border.all(color: Tailwind.slate200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: "Search subjects...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Tailwind.slate400),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subject Grid
              Expanded(
                child: activeList.isEmpty
                    ? Center(
                        child: Text(
                          gradeHasTextbooks(_selectedGrade)
                              ? "No subjects found"
                              : "Textbooks coming soon",
                          style: TextStyle(color: Tailwind.slate500),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.sizeOf(context).width < 500
                              ? 2
                              : MediaQuery.sizeOf(context).width < 850
                              ? 3
                              : 5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 170,
                        ),
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          final subject = activeList[index];
                          return GestureDetector(
                            onTap: !gradeHasTextbooks(_selectedGrade)
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          initialSubject: subject['name'],
                                          initialGradeLevel: _selectedGrade,
                                        ),
                                      ),
                                    );
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Tailwind
                                    .pastels[index % Tailwind.pastels.length],
                                borderRadius: Tailwind.rounded2Xl,
                                boxShadow: Tailwind.shadowSm,
                                border: Border.all(color: Tailwind.slate200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: subject['color'].withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      subject['icon'],
                                      size: 28,
                                      color: subject['color'],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Text(
                                      subject['name'],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Tailwind.slate800,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
