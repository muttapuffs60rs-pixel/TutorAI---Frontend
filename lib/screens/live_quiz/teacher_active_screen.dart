import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../theme/tailwind_theme.dart';

class TeacherActiveScreen extends StatefulWidget {
  final String sessionCode;
  final String sessionId;
  final String title;
  final List<dynamic> questions;
  final RealtimeChannel channel;

  const TeacherActiveScreen({
    super.key,
    required this.sessionCode,
    required this.sessionId,
    required this.title,
    required this.questions,
    required this.channel,
  });

  @override
  State<TeacherActiveScreen> createState() => _TeacherActiveScreenState();
}

class _TeacherActiveScreenState extends State<TeacherActiveScreen> {
  int _currentIndex = 0;
  int _answersReceived = 0;
  int _totalStudents = 0;
  bool _isLoading = false;
  List<dynamic> _leaderboard = [];
  bool _showLeaderboard = false;

  // ── Timer state ─────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 60;
  bool _timesUp = false;
  String _currentTimerMode = 'auto';

  late final RealtimeChannel _responsesChannel;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _countStudents();
    _loadLeaderboard();
    _startTimer();
  }

  // ── Presence ────────────────────────────────────────────────────────────────
  void _countStudents() {
    final state = widget.channel.presenceState();
    int count = 0;
    for (final entry in state) {
      for (final p in entry.presences) {
        if (p.payload['role'] == 'student') count++;
      }
    }
    setState(() => _totalStudents = count);
  }

  // ── Realtime ─────────────────────────────────────────────────────────────────
  void _setupRealtime() {
    // Use a unique channel name to avoid collisions
    _responsesChannel = supabase.channel('teacher_responses:${widget.sessionId}');
    _responsesChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'quiz_responses',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'session_id',
          value: widget.sessionId,
        ),
        callback: (payload) {
          // Count every new response — teacher just wants to see X/N answered
          if (mounted) setState(() => _answersReceived++);
        },
      )
      .subscribe();

    widget.channel.onPresenceSync((payload) => _countStudents());
  }

  // ── Timer ───────────────────────────────────────────────────────────────────
  void _startTimer() {
    _cancelTimer();
    if (_currentIndex >= widget.questions.length) return;

    final q = widget.questions[_currentIndex];
    final seconds = (q['timer_seconds'] as int?) ?? 60;
    final mode = (q['timer_mode'] as String?) ?? 'auto';

    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _timesUp = false;
      _currentTimerMode = mode;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timesUp = true;
          timer.cancel();
          // Auto-advance to leaderboard when timer expires
          if (_currentTimerMode == 'auto' && !_showLeaderboard && !_isLoading) {
            _nextStep();
          }
        }
      });
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Color get _timerColor {
    if (_totalSeconds == 0) return Tailwind.slate400;
    final ratio = _remainingSeconds / _totalSeconds;
    if (ratio > 0.4) return const Color(0xFF059669); // green
    if (ratio > 0.2) return const Color(0xFFD97706); // amber
    return const Color(0xFFDC2626);                  // red
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _cancelTimer();
    supabase.removeChannel(_responsesChannel);
    supabase.removeChannel(widget.channel);
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────
  Future<void> _loadLeaderboard() async {
    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final res = await http.get(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/${widget.sessionCode}/leaderboard'),
        headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => _leaderboard = jsonDecode(res.body)['leaderboard']);
      }
    } catch (e) {
      debugPrint('Leaderboard error: $e');
    }
  }

  Future<void> _nextStep() async {
    setState(() => _isLoading = true);
    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';

      // Always advance to next question directly
      _cancelTimer();

      final res = await http.post(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/${widget.sessionCode}/next'),
        headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'completed') {
          await widget.channel.sendBroadcastMessage(event: 'quiz_end', payload: {});
          
          // Quiz finished! Fetch leaderboard and show it
          await _loadLeaderboard();
          if (mounted) {
            setState(() {
              _showLeaderboard = true;
            });
            _showCompletionDialog();
          }
        } else {
          final nextIdx = data['current_question_index'] as int;
          final nextQ = widget.questions[nextIdx];
          // Broadcast next question WITH its timer data so students sync up
          await widget.channel.sendBroadcastMessage(
            event: 'next_question',
            payload: {
              'index': nextIdx,
              'timer_seconds': (nextQ['timer_seconds'] as int?) ?? 60,
              'timer_mode': (nextQ['timer_mode'] as String?) ?? 'auto',
            },
          );
          if (mounted) {
            setState(() {
              _currentIndex = nextIdx;
              _showLeaderboard = false;
              _answersReceived = 0;
            });
            _startTimer();
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Quiz Completed! 🎉', style: TextStyle(color: Tailwind.indigo600, fontWeight: FontWeight.bold)),
        content: const Text('All questions are done. The final leaderboard is updated.'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(c); Navigator.pop(context); },
            child: const Text('Return to Home', style: TextStyle(color: Tailwind.slate600)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_showLeaderboard) return _buildLeaderboardView();
    return _buildQuestionView();
  }

  // Circular countdown ring shared between teacher and student views
  Widget _buildTimerRing() {
    if (_timesUp) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_rounded, color: Color(0xFFDC2626), size: 16),
            SizedBox(width: 6),
            Text("Time's up!", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 88, height: 88,
          child: CircularProgressIndicator(
            value: _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0,
            backgroundColor: Tailwind.slate100,
            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
            strokeWidth: 6,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_remainingSeconds',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _timerColor),
            ),
            Text(
              'SEC',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _timerColor, letterSpacing: 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    final q = widget.questions[_currentIndex];

    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '${widget.title} — Q${_currentIndex + 1}/${widget.questions.length}',
          style: const TextStyle(color: Tailwind.slate800, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Mode badge (Auto / Manual)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _currentTimerMode == 'auto' ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentTimerMode == 'auto' ? Icons.timer_rounded : Icons.touch_app_rounded,
                  size: 13,
                  color: _currentTimerMode == 'auto' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  _currentTimerMode == 'auto' ? 'Auto' : 'Manual',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _currentTimerMode == 'auto' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: Tailwind.slate200,
              valueColor: const AlwaysStoppedAnimation<Color>(Tailwind.indigo600),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Question card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Tailwind.white, borderRadius: Tailwind.rounded3Xl, boxShadow: Tailwind.shadowLg),
                      child: Column(
                        children: [
                          const Text('CURRENT QUESTION', style: TextStyle(color: Tailwind.slate400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          Text(q['question_text'], textAlign: TextAlign.center, style: const TextStyle(color: Tailwind.slate800, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── Countdown ring ───────────────────────────────────────
                    _buildTimerRing(),
                    const SizedBox(height: 32),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBox(title: 'RESPONSES', value: '$_answersReceived/$_totalStudents', icon: Icons.how_to_vote_rounded, color: Tailwind.amber500),
                        _StatBox(title: 'STUDENTS', value: '$_totalStudents', icon: Icons.people_alt_rounded, color: Tailwind.emerald500),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Tailwind.white, border: Border(top: BorderSide(color: Tailwind.slate200))),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Tailwind.indigo600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(_currentIndex >= widget.questions.length - 1 ? 'Finish Quiz' : 'Next Question', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardView() {
    final isLast = _currentIndex == widget.questions.length - 1;

    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Live Leaderboard 🏆', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Tailwind.slate500), onPressed: _loadLeaderboard),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _leaderboard.isEmpty
                ? const Center(child: Text('No scores yet.', style: TextStyle(color: Tailwind.slate500, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _leaderboard.length,
                    itemBuilder: (context, index) {
                      final item = _leaderboard[index];
                      final isTop3 = index < 3;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isTop3 ? Tailwind.indigo50 : Tailwind.white,
                          borderRadius: Tailwind.roundedXl,
                          border: Border.all(color: isTop3 ? Tailwind.indigo200 : Tailwind.slate200),
                        ),
                        child: Row(
                          children: [
                            Text('#${index + 1}', style: TextStyle(color: isTop3 ? Tailwind.indigo600 : Tailwind.slate400, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Expanded(child: Text(item['student_name'], style: TextStyle(color: Tailwind.slate800, fontSize: 16, fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Tailwind.indigo600, borderRadius: BorderRadius.circular(20)),
                              child: Text('${item['total_score']} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Tailwind.white, border: Border(top: BorderSide(color: Tailwind.slate200))),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? Tailwind.rose500 : Tailwind.indigo600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(isLast ? 'End Quiz' : 'Next Question', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat box widget ──────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Tailwind.slate800, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Tailwind.slate500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ],
    );
  }
}
