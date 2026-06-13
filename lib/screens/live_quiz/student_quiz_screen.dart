import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/tailwind_theme.dart';

class StudentQuizScreen extends StatefulWidget {
  final String sessionCode;
  final String sessionId;
  final String studentName;
  final String title;
  final List<dynamic> questions;
  final String initialStatus;
  final int initialQuestionIndex;

  const StudentQuizScreen({
    super.key,
    required this.sessionCode,
    required this.sessionId,
    required this.studentName,
    required this.title,
    required this.questions,
    required this.initialStatus,
    required this.initialQuestionIndex,
  });

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  late String _status;
  late int _currentIndex;
  late final RealtimeChannel _channel;
  
  bool _isSubmitting = false;
  bool _hasAnsweredCurrent = false;
  bool _wasCorrect = false;
  String _correctAnswerMsg = '';
  
  final _fillBlankController = TextEditingController();

  List<dynamic> _finalLeaderboard = [];
  int _myRank = 0;
  int _myScore = 0;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _currentIndex = widget.initialQuestionIndex;
    _setupRealtime();
  }

  void _setupRealtime() {
    _channel = supabase.channel('quiz:${widget.sessionCode}');
    
    _channel.onBroadcast(event: 'quiz_start', callback: (payload) {
      if (mounted) setState(() { _status = 'active'; _currentIndex = 0; _resetQuestionState(); });
    });

    _channel.onBroadcast(event: 'next_question', callback: (payload) {
      if (mounted) setState(() { 
        _currentIndex = payload['index']; 
        _resetQuestionState();
      });
    });

    _channel.onBroadcast(event: 'quiz_end', callback: (payload) async {
      await _fetchFinalLeaderboard();
      if (mounted) setState(() { _status = 'completed'; });
    });

    _channel.subscribe((status, error) async {
      if (status == 'SUBSCRIBED') {
        await _channel.track({'role': 'student', 'name': widget.studentName});
      }
    });
  }

  @override
  void dispose() {
    _fillBlankController.dispose();
    supabase.removeChannel(_channel);
    super.dispose();
  }

  void _resetQuestionState() {
    _hasAnsweredCurrent = false;
    _wasCorrect = false;
    _correctAnswerMsg = '';
    _fillBlankController.clear();
  }

  Future<void> _submitAnswer(String answer) async {
    if (answer.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final qId = widget.questions[_currentIndex]['id'];

      final res = await http.post(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/${widget.sessionCode}/answer'),
        headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'question_id': qId,
          'submitted_answer': answer,
          'student_name': widget.studentName,
        }),
      );

      if (mounted) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _hasAnsweredCurrent = true;
            _wasCorrect = data['is_correct'];
            if (!_wasCorrect) _correctAnswerMsg = data['correct_answer'];
          });
        } else if (res.statusCode == 409) {
          // Already answered
          setState(() { _hasAnsweredCurrent = true; });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${jsonDecode(res.body)['detail'] ?? res.body}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _fetchFinalLeaderboard() async {
    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final res = await http.get(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/${widget.sessionCode}/leaderboard'),
        headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['leaderboard'] as List<dynamic>;
        int rank = 0;
        int score = 0;
        for (int i = 0; i < data.length; i++) {
          if (data[i]['student_name'] == widget.studentName) {
            rank = i + 1;
            score = data[i]['total_score'];
            break;
          }
        }
        if (mounted) {
          setState(() {
            _finalLeaderboard = data;
            _myRank = rank;
            _myScore = score;
          });
        }
      }
    } catch (e) {
      debugPrint("Leaderboard error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'waiting') return _buildWaitingScreen();
    if (_status == 'completed') return _buildCompletedScreen();
    return _buildActiveScreen();
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: Tailwind.emerald500,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 64),
            const SizedBox(height: 24),
            const Text("You're in!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('See your nickname on screen?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
            const SizedBox(height: 48),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
            const SizedBox(height: 24),
            const Text('Waiting for teacher to start...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: Tailwind.indigo600,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Text('Quiz Complete!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Here is how you did:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: Tailwind.rounded2Xl, boxShadow: Tailwind.shadowXl),
              child: Column(
                children: [
                  Text(_myRank > 0 ? '#$_myRank' : '-', style: const TextStyle(color: Tailwind.slate800, fontSize: 64, fontWeight: FontWeight.w900)),
                  const Text('YOUR RANK', style: TextStyle(color: Tailwind.slate400, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 24),
                  const Divider(color: Tailwind.slate100),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('$_myScore', style: const TextStyle(color: Tailwind.indigo600, fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text('CORRECT', style: TextStyle(color: Tailwind.slate400, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('${widget.questions.length}', style: const TextStyle(color: Tailwind.slate800, fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text('TOTAL', style: TextStyle(color: Tailwind.slate400, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Tailwind.indigo600,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                ),
                child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreen() {
    final q = widget.questions[_currentIndex];

    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white, elevation: 0, automaticallyImplyLeading: false,
        title: Text('${widget.title} — Q${_currentIndex + 1}/${widget.questions.length}', style: const TextStyle(color: Tailwind.slate800, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Tailwind.indigo50, borderRadius: BorderRadius.circular(20)),
                child: Text(widget.studentName, style: const TextStyle(color: Tailwind.indigo600, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: Tailwind.slate200,
              valueColor: const AlwaysStoppedAnimation<Color>(Tailwind.indigo600),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Tailwind.white, borderRadius: Tailwind.rounded3Xl, boxShadow: Tailwind.shadowMd),
                      child: Text(q['question_text'], textAlign: TextAlign.center, style: const TextStyle(color: Tailwind.slate800, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),
                    if (_hasAnsweredCurrent)
                      _buildFeedback()
                    else if (q['question_type'] == 'mcq')
                      _buildMcqOptions(q['options'])
                    else
                      _buildFillBlankInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _wasCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: Tailwind.rounded2Xl,
        border: Border.all(color: _wasCorrect ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Icon(_wasCorrect ? Icons.check_circle_outline : Icons.cancel_outlined, color: _wasCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626), size: 64),
          const SizedBox(height: 16),
          Text(_wasCorrect ? 'Correct!' : 'Incorrect', style: TextStyle(color: _wasCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B), fontSize: 24, fontWeight: FontWeight.bold)),
          if (!_wasCorrect && _correctAnswerMsg.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Correct Answer:', style: TextStyle(color: Tailwind.slate500, fontSize: 13)),
            const SizedBox(height: 4),
            Text(_correctAnswerMsg, style: const TextStyle(color: Tailwind.slate800, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Waiting for teacher...', style: TextStyle(color: Tailwind.slate500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMcqOptions(List<dynamic> options) {
    final colors = [
      const Color(0xFFE23636), // Red
      const Color(0xFF1368CE), // Blue
      const Color(0xFFD89E00), // Yellow
      const Color(0xFF26890C), // Green
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) {
        return ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitAnswer(options[i]),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors[i % colors.length],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
            padding: const EdgeInsets.all(16),
          ),
          child: Text(options[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildFillBlankInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _fillBlankController,
          enabled: !_isSubmitting,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Tailwind.slate800),
          decoration: InputDecoration(
            hintText: 'Type your answer here',
            filled: true, fillColor: Tailwind.white,
            border: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: BorderSide(color: Tailwind.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: BorderSide(color: Tailwind.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: const BorderSide(color: Tailwind.indigo600, width: 2)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitAnswer(_fillBlankController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Tailwind.indigo600, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('SUBMIT ANSWER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      ],
    );
  }
}
