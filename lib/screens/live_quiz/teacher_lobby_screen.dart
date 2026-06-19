import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../theme/tailwind_theme.dart';
import 'teacher_active_screen.dart';

class TeacherLobbyScreen extends StatefulWidget {
  final String sessionCode;
  final String sessionId;
  final String title;
  final int questionCount;
  final List<dynamic> questions;

  const TeacherLobbyScreen({
    super.key,
    required this.sessionCode,
    required this.sessionId,
    required this.title,
    required this.questionCount,
    required this.questions,
  });

  @override
  State<TeacherLobbyScreen> createState() => _TeacherLobbyScreenState();
}

class _TeacherLobbyScreenState extends State<TeacherLobbyScreen> {
  int _studentCount = 0;
  bool _isStarting = false;
  late final _channel = supabase.channel('quiz:${widget.sessionCode}');

  @override
  void initState() {
    super.initState();
    _setupPresence();
  }

  void _setupPresence() {
    _channel
      .onPresenceSync((payload) {
        final state = _channel.presenceState();
        int count = 0;
        for (final entry in state) {
          for (final p in entry.presences) {
            if (p.payload['role'] == 'student') count++;
          }
        }
        if (mounted) setState(() => _studentCount = count);
      })
      .subscribe((status, error) async {
        if (status == 'SUBSCRIBED') {
          await _channel.track({'role': 'teacher'});
        }
      });
  }

  bool _navigatingToActive = false;

  @override
  void dispose() {
    if (!_navigatingToActive) {
      supabase.removeChannel(_channel);
    }
    super.dispose();
  }

  Future<void> _startQuiz() async {
    if (_studentCount == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Start without students?'),
          content: const Text('No students have joined yet. Start anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Start')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isStarting = true);
    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final res = await http.post(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/${widget.sessionCode}/start'),
        headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (res.statusCode == 200) {
        // Broadcast quiz start WITH Q0 timer data so students sync their countdown
        final firstQ = widget.questions.isNotEmpty ? widget.questions[0] : <String, dynamic>{};
        await _channel.sendBroadcastMessage(
          event: 'quiz_start',
          payload: {
            'timer_seconds': (firstQ['timer_seconds'] as int?) ?? 60,
            'timer_mode': (firstQ['timer_mode'] as String?) ?? 'auto',
          },
        );

        _navigatingToActive = true;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherActiveScreen(
          sessionCode: widget.sessionCode,
          sessionId: widget.sessionId,
          title: widget.title,
          questions: widget.questions,
          channel: _channel, // Pass channel to next screen to reuse presence
        )));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${jsonDecode(res.body)['detail'] ?? res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.indigo600,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text('LOBBY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Spacer(),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Join at', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: Tailwind.rounded2Xl, boxShadow: Tailwind.shadowLg),
                      child: Text(widget.sessionCode, style: const TextStyle(color: Tailwind.slate900, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 8)),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: Tailwind.roundedXl),
                      child: Column(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          Text('$_studentCount', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                          const Text('STUDENTS JOINED', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.title, style: const TextStyle(color: Tailwind.slate800, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('${widget.questionCount} Questions', style: const TextStyle(color: Tailwind.slate500, fontSize: 15), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isStarting ? null : _startQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Tailwind.indigo600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                        elevation: 0,
                      ),
                      child: _isStarting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('START QUIZ NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
