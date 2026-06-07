import 'package:flutter/material.dart';
import '../theme/tailwind_theme.dart';
import '../constants.dart';

class SubjectPickerSheet extends StatefulWidget {
  final int initialGrade;
  final Function(int grade, String subject) onSubjectSelected;

  const SubjectPickerSheet({
    super.key,
    required this.initialGrade,
    required this.onSubjectSelected,
  });

  @override
  State<SubjectPickerSheet> createState() => _SubjectPickerSheetState();
}

class _SubjectPickerSheetState extends State<SubjectPickerSheet> {
  late int _selectedGrade;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGrade;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activeList = _selectedGrade == 10 ? class10Subjects : class12Subjects;
    if (_searchQuery.isNotEmpty) {
      activeList = activeList.where((s) => s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Tailwind.slate50,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: Tailwind.slate300, borderRadius: Tailwind.roundedFull),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text("Change Subject", style: TextStyle(color: Tailwind.slate800, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Toggle Class
                Container(
                  decoration: BoxDecoration(color: Tailwind.slate200, borderRadius: Tailwind.roundedXl),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedGrade == 10 ? Tailwind.white : Colors.transparent,
                              borderRadius: Tailwind.roundedLg,
                              boxShadow: _selectedGrade == 10 ? Tailwind.shadowSm : null,
                            ),
                            child: Center(
                              child: Text(
                                "Class 10",
                                style: TextStyle(fontWeight: FontWeight.bold, color: _selectedGrade == 10 ? Tailwind.indigo600 : Tailwind.slate500),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedGrade == 12 ? Tailwind.white : Colors.transparent,
                              borderRadius: Tailwind.roundedLg,
                              boxShadow: _selectedGrade == 12 ? Tailwind.shadowSm : null,
                            ),
                            child: Center(
                              child: Text(
                                "Class 12",
                                style: TextStyle(fontWeight: FontWeight.bold, color: _selectedGrade == 12 ? Tailwind.indigo600 : Tailwind.slate500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Tailwind.white,
                    borderRadius: Tailwind.roundedXl,
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
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          Expanded(
            child: activeList.isEmpty
                ? const Center(child: Text("No subjects found", style: TextStyle(color: Tailwind.slate500)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: activeList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final subject = activeList[index];
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSubjectSelected(_selectedGrade, subject['name']);
                        },
                        shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl, side: const BorderSide(color: Tailwind.slate100)),
                        tileColor: Tailwind.white,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: subject['color'].withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(subject['icon'], color: subject['color'], size: 24),
                        ),
                        title: Text(subject['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Tailwind.slate800)),
                        trailing: const Icon(Icons.chevron_right, color: Tailwind.slate300),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
