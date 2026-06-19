import 'dart:async';
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

  // ignore: unused_field — used in _fetchFinalLeaderboard and completed screen leaderboard
  List<dynamic> _finalLeaderboard = [];
  int _myRank = 0;
  num _myScore = 0;

  // ── Timer state ─────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 60;
  bool _timesUp = false;
  // ignore: unused_field — used in _startTimer and broadcast handling
  String _currentTimerMode = 'auto';

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _currentIndex = widget.initialQuestionIndex;
    _setupRealtime();
    // If student joins a mid-session active quiz, start timer with defaults
    if (_status == 'active') {
      _startTimer(60, 'manual'); // conservative default — teacher controls pace
    }
  }

  void _setupRealtime() {
    _channel = supabase.channel('quiz:${widget.sessionCode}');

    // Teacher started the quiz → Q0 timer data is in the payload
    _channel.onBroadcast(event: 'quiz_start', callback: (payload) {
      if (mounted) {
        setState(() { _status = 'active'; _currentIndex = 0; _resetQuestionState(); });
        final seconds = int.tryParse(payload['timer_seconds']?.toString() ?? '60') ?? 60;
        final mode = payload['timer_mode']?.toString() ?? 'auto';
        _startTimer(seconds, mode);
      }
    });

    // Teacher moved to next question — includes timer data for that question
    _channel.onBroadcast(event: 'next_question', callback: (payload) {
      if (mounted) {
        final newIdx = int.tryParse(payload['index']?.toString() ?? '0') ?? 0;
        if (newIdx > _currentIndex) {
          setState(() {
            _currentIndex = newIdx;
            _resetQuestionState();
          });
          final seconds = int.tryParse(payload['timer_seconds']?.toString() ?? '60') ?? 60;
          final mode = payload['timer_mode']?.toString() ?? 'auto';
          _startTimer(seconds, mode);
        }
      }
    });

    // Fallback: If WebSockets drop the broadcast, listen to database updates
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'quiz_sessions',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: widget.sessionId),
      callback: (payload) async {
        if (!mounted) return;
        final newRecord = payload.newRecord;
        if (newRecord['status'] == 'completed') {
           _cancelTimer();
           await _fetchFinalLeaderboard();
           if (mounted) setState(() => _status = 'completed');
        } else if (newRecord['current_question_index'] != null) {
          final newIdx = int.tryParse(newRecord['current_question_index'].toString()) ?? 0;
          if (newIdx > _currentIndex && newIdx < widget.questions.length) {
            setState(() {
              _currentIndex = newIdx;
              _resetQuestionState();
            });
            final q = widget.questions[_currentIndex];
            final seconds = int.tryParse(q['timer_seconds']?.toString() ?? '60') ?? 60;
            final mode = q['timer_mode']?.toString() ?? 'auto';
            _startTimer(seconds, mode);
          }
        }
      }
    );

    _channel.onBroadcast(event: 'quiz_end', callback: (payload) async {
      _cancelTimer();
      await _fetchFinalLeaderboard();
      if (mounted) setState(() => _status = 'completed');
    });

    _channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel.track({'role': 'student', 'name': widget.studentName});
      }
    });
  }

  // ── Timer ───────────────────────────────────────────────────────────────────
  void _startTimer(int seconds, String mode) {
    _cancelTimer();
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
          // Lock out the student from answering when time's up
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
    final ratio = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    if (ratio > 0.4) return const Color(0xFF059669); // green
    if (ratio > 0.2) return const Color(0xFFD97706); // amber
    return const Color(0xFFDC2626);                  // red
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _cancelTimer();
    _fillBlankController.dispose();
    supabase.removeChannel(_channel);
    super.dispose();
  }

  void _resetQuestionState() {
    _cancelTimer();
    _hasAnsweredCurrent = false;
    _wasCorrect = false;
    _correctAnswerMsg = '';
    _timesUp = false;
    _fillBlankController.clear();
  }

  // ── Submit answer ────────────────────────────────────────────────────────────
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
          setState(() => _hasAnsweredCurrent = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${jsonDecode(res.body)['detail'] ?? res.body}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        num score = 0;
        for (int i = 0; i < data.length; i++) {
          if (data[i]['student_name'] == widget.studentName) {
            rank = i + 1;
            score = data[i]['total_score'] ?? 0;
            break;
          }
        }
        if (mounted) setState(() { _finalLeaderboard = data; _myRank = rank; _myScore = score; });
      }
    } catch (e) {
      debugPrint('Leaderboard error: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_status == 'waiting') return _buildWaitingScreen();
    if (_status == 'completed') return _buildCompletedScreen();
    return _buildActiveScreen();
  }

  // ── Waiting screen ────────────────────────────────────────────────────────────
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
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Text('SCORING RULES', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Correct: +1 mark', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                  SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Wrong: -0.5 marks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
            const SizedBox(height: 24),
            const Text('Waiting for teacher to start...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Completed screen ──────────────────────────────────────────────────────────
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
                      Column(children: [
                        Text('$_myScore', style: const TextStyle(color: Tailwind.indigo600, fontSize: 32, fontWeight: FontWeight.bold)),
                        const Text('SCORE', style: TextStyle(color: Tailwind.slate400, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                      Column(children: [
                        Text('${widget.questions.length}', style: const TextStyle(color: Tailwind.slate800, fontSize: 32, fontWeight: FontWeight.bold)),
                        const Text('TOTAL', style: TextStyle(color: Tailwind.slate400, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Active quiz screen ────────────────────────────────────────────────────────
  Widget _buildActiveScreen() {
    final q = widget.questions[_currentIndex];
    final bool canAnswer = !_hasAnsweredCurrent && !_timesUp && !_isSubmitting;

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
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Tailwind.indigo50, borderRadius: BorderRadius.circular(20)),
                child: Text(widget.studentName, style: const TextStyle(color: Tailwind.indigo600, fontWeight: FontWeight.bold)),
              ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Timer ring ─────────────────────────────────────────
                    Center(child: _buildTimerRing()),
                    const SizedBox(height: 20),
                    // ── Question card ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Tailwind.white, borderRadius: Tailwind.rounded3Xl, boxShadow: Tailwind.shadowMd),
                      child: Text(q['question_text'], textAlign: TextAlign.center, style: const TextStyle(color: Tailwind.slate800, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                    // ── Time's up banner (when expired and not yet answered)
                    if (_timesUp && !_hasAnsweredCurrent)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: Tailwind.rounded2Xl,
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.timer_off_rounded, color: Color(0xFFDC2626), size: 36),
                            SizedBox(height: 8),
                            Text("Time's up!", style: TextStyle(color: Color(0xFFDC2626), fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Waiting for teacher...', style: TextStyle(color: Tailwind.slate500, fontSize: 13)),
                          ],
                        ),
                      )
                    else if (_hasAnsweredCurrent)
                      _buildFeedback()
                    else if (q['question_type'] == 'mcq')
                      _buildMcqOptions(q['options'], canAnswer)
                    else
                      _buildFillBlankInput(canAnswer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timer ring widget ─────────────────────────────────────────────────────────
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
          width: 80, height: 80,
          child: CircularProgressIndicator(
            value: _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0,
            backgroundColor: Tailwind.slate100,
            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
            strokeWidth: 5,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_remainingSeconds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _timerColor)),
            Text('SEC', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _timerColor, letterSpacing: 1)),
          ],
        ),
      ],
    );
  }

  // ── Answer widgets ────────────────────────────────────────────────────────────
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
          Icon(_wasCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: _wasCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626), size: 64),
          const SizedBox(height: 16),
          Text(_wasCorrect ? 'Correct!' : 'Incorrect',
              style: TextStyle(color: _wasCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B), fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildMcqOptions(List<dynamic> options, bool canAnswer) {
    final colors = [
      const Color(0xFFE23636),
      const Color(0xFF1368CE),
      const Color(0xFFD89E00),
      const Color(0xFF26890C),
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
          onPressed: canAnswer ? () => _submitAnswer(options[i]) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAnswer ? colors[i % colors.length] : Tailwind.slate300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
            padding: const EdgeInsets.all(16),
          ),
          child: Text(options[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildFillBlankInput(bool canAnswer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _fillBlankController,
          enabled: canAnswer,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Tailwind.slate800),
          decoration: InputDecoration(
            hintText: canAnswer ? 'Type your answer here' : 'Time\'s up — no submission',
            filled: true, fillColor: Tailwind.white,
            border: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: const BorderSide(color: Tailwind.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: const BorderSide(color: Tailwind.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: Tailwind.roundedXl, borderSide: const BorderSide(color: Tailwind.indigo600, width: 2)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: canAnswer ? () => _submitAnswer(_fillBlankController.text) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAnswer ? Tailwind.indigo600 : Tailwind.slate300,
            foregroundColor: Colors.white,
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
