import 'package:flutter/material.dart';
import '../main.dart'; 
import '../theme/tailwind_theme.dart';
import '../constants.dart';
import 'chat_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  int _selectedGrade = 10;
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
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
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
    List<Map<String, dynamic>> activeList = _selectedGrade == 10 ? class10Subjects : class12Subjects;
    if (_searchQuery.isNotEmpty) {
      activeList = activeList.where((s) => s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Standard Selection Toggle
              Container(
                decoration: BoxDecoration(
                  color: Tailwind.slate200,
                  borderRadius: Tailwind.roundedXl,
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedGrade = 10;
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedGrade == 10 ? Tailwind.white : Colors.transparent,
                            borderRadius: Tailwind.roundedLg,
                            boxShadow: _selectedGrade == 10 ? Tailwind.shadowSm : null,
                          ),
                          child: Center(
                            child: Text(
                              "Class 10",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedGrade == 10 ? Tailwind.indigo600 : Tailwind.slate500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedGrade = 12;
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedGrade == 12 ? Tailwind.white : Colors.transparent,
                            borderRadius: Tailwind.roundedLg,
                            boxShadow: _selectedGrade == 12 ? Tailwind.shadowSm : null,
                          ),
                          child: Center(
                            child: Text(
                              "Class 12",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedGrade == 12 ? Tailwind.indigo600 : Tailwind.slate500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                "Iniku enna subject padikalam?",
                style: TextStyle(color: Tailwind.slate800, fontSize: 24, fontWeight: FontWeight.w800),
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
                    ? Center(child: Text("No subjects found", style: TextStyle(color: Tailwind.slate500)))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          final subject = activeList[index];
                          return GestureDetector(
                            onTap: () {
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
                                color: Tailwind.white,
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
                                    child: Icon(subject['icon'], size: 28, color: subject['color']),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      subject['name'],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Tailwind.slate800, fontSize: 11, fontWeight: FontWeight.bold),
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
