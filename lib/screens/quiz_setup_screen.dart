import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart'; // To access Supabase user
import 'active_quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  int _selectedGrade = 10;
  String _selectedSubject = 'Social';
  List<String> _selectedUnits = [];
  String _selectedSection = 'All Sections';
  int _numQuestions = 10;
  bool _isLoading = false; // <-- The magic loading variable!

  final List<int> _grades = [6, 7, 8, 9, 10, 11, 12];
  final List<String> _subjects = ['Science', 'Maths', 'Social', 'English', 'Tamil'];
  final List<int> _questionCounts = [10, 25];

  final List<String> _availableUnits = ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5'];
  final List<String> _availableSections = ['All Sections', 'Section 1.1', 'Section 1.2', 'Section 1.3'];

  void _showMultiSelectUnitsDialog() async {
    final List<String>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          items: _availableUnits,
          initialSelectedItems: _selectedUnits,
        );
      },
    );

    if (results != null) {
      setState(() {
        _selectedUnits = results;
        if (_selectedUnits.length != 1) {
          _selectedSection = 'All Sections';
        }
      });
    }
  }

  // THE NEW, CONNECTED FUNCTION
  Future<void> _startTest() async {
    if (_selectedUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one unit!')),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You must be logged in!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/generate-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.id,
          'grade_level': _selectedGrade,
          'subject': _selectedSubject,
          'units': _selectedUnits,
          'section': _selectedUnits.length == 1 ? _selectedSection : 'All Sections',
          'num_questions': _numQuestions,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Remove the old SnackBar print message and add the Navigator!
        if (mounted) {
          // data['questions'] pulls the array of questions out of the JSON!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveQuizScreen(questions: data['questions']),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to the backend server.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.quiz, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Test Your Knowledge',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Standard',
                    icon: Icons.school,
                    value: _selectedGrade,
                    items: _grades.map((g) => DropdownMenuItem(value: g, child: Text('Class $g'))).toList(),
                    onChanged: (val) => setState(() => _selectedGrade = val as int),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Subject',
                    icon: Icons.menu_book,
                    value: _selectedSubject,
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedSubject = val as String),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Select Units', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showMultiSelectUnitsDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF282A2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedUnits.isEmpty ? 'Tap to select units...' : _selectedUnits.join(', '),
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedUnits.length == 1) ...[
              _buildDropdown(
                label: 'Specific Section (Optional)',
                icon: Icons.segment,
                value: _selectedSection,
                items: _availableSections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedSection = val as String),
              ),
              const SizedBox(height: 24),
            ],

            _buildDropdown(
              label: 'Number of Questions',
              icon: Icons.format_list_numbered,
              value: _numQuestions,
              items: _questionCounts.map((q) => DropdownMenuItem(value: q, child: Text('$q Questions'))).toList(),
              onChanged: (val) => setState(() => _numQuestions = val as int),
            ),
            const SizedBox(height: 40),

            // DYNAMIC BUTTON / SPINNER
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            else
              ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Test', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required IconData icon, required dynamic value, required List<DropdownMenuItem<dynamic>> items, required Function(dynamic) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF282A2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              isExpanded: true,
              value: value,
              dropdownColor: const Color(0xFF282A2C),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;
  final List<String> initialSelectedItems;

  const MultiSelectDialog({super.key, required this.items, required this.initialSelectedItems});

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  final List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.initialSelectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1F20),
      title: const Text('Select Units'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items.map((item) {
            return CheckboxListTile(
              value: _selectedItems.contains(item),
              title: Text(item),
              activeColor: Colors.blueAccent,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? isChecked) {
                setState(() {
                  if (isChecked == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          onPressed: () => Navigator.pop(context), 
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context, _selectedItems), 
        ),
      ],
    );
  }
}