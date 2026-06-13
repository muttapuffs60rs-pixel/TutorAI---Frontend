import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../theme/tailwind_theme.dart';
import 'student_quiz_screen.dart';

class StudentJoinScreen extends StatefulWidget {
  const StudentJoinScreen({super.key});

  @override
  State<StudentJoinScreen> createState() => _StudentJoinScreenState();
}

class _StudentJoinScreenState extends State<StudentJoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth if available
    final user = supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? user?.userMetadata?['username'] ?? '';
    _nameController.text = name;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinQuiz() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.length != 6) {
      _snack('Please enter a valid 6-character session code'); return;
    }
    if (name.isEmpty) {
      _snack('Please enter your name'); return;
    }

    setState(() => _isLoading = true);

    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';
      
      // Fetch session info
      final res = await http.get(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/$code'),
        headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'completed') {
          _snack('This quiz has already ended.');
          return;
        }

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentQuizScreen(
          sessionCode: code,
          sessionId: data['id'],
          studentName: name,
          title: data['title'],
          questions: data['questions'],
          initialStatus: data['status'],
          initialQuestionIndex: data['current_question_index'],
        )));
      } else {
        _snack('Error: ${jsonDecode(res.body)['detail'] ?? res.body}');
      }
    } catch (e) {
      _snack('Error connecting to server. Check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.emerald500,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  const Text('JOIN QUIZ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.gamepad_rounded, color: Colors.white, size: 64),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: Tailwind.rounded3Xl, boxShadow: Tailwind.shadowXl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Session PIN', style: TextStyle(color: Tailwind.slate500, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 8, color: Tailwind.slate800),
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(color: Tailwind.slate300),
                              filled: true, fillColor: Tailwind.slate50,
                              border: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Your Name', style: TextStyle(color: Tailwind.slate500, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Tailwind.slate800),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              filled: true, fillColor: Tailwind.slate50,
                              border: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.person, color: Tailwind.slate400),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _joinQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Tailwind.emerald600, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('JOIN NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
