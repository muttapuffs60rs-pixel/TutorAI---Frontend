import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../theme/tailwind_theme.dart';
import 'teacher_lobby_screen.dart';

class TeacherCreateQuizScreen extends StatefulWidget {
  const TeacherCreateQuizScreen({super.key});
  @override
  State<TeacherCreateQuizScreen> createState() => _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState extends State<TeacherCreateQuizScreen> {
  final _titleController = TextEditingController();
  final List<_QuestionDraft> _questions = [];
  bool _isLoading = false;

  @override
  void dispose() { _titleController.dispose(); super.dispose(); }

  void _addQuestion() => setState(() => _questions.add(_QuestionDraft()));
  void _removeQuestion(int i) => setState(() => _questions.removeAt(i));

  Future<void> _createSession() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a quiz title'); return;
    }
    if (_questions.isEmpty) { _snack('Add at least one question'); return; }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) { _snack('Question ${i + 1} text is empty'); return; }
      if (q.correctAnswer.trim().isEmpty) { _snack('Question ${i + 1} has no correct answer selected'); return; }
      if (q.type == 'mcq') {
        for (int j = 0; j < q.options.length; j++) {
          if (q.options[j].trim().isEmpty) { _snack('Question ${i + 1}: Option ${String.fromCharCode(65 + j)} is empty'); return; }
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final questions = _questions.asMap().entries.map((e) {
        final q = e.value;
        return {
          'question_text': q.questionText.trim(),
          'question_type': q.type,
          'options': q.type == 'mcq' ? q.options.map((o) => o.trim()).toList() : null,
          'correct_answer': q.correctAnswer.trim(),
          'sort_order': e.key,
          'points': 1,
        };
      }).toList();

      final res = await http.post(
        Uri.parse('https://akka-tutor-backend.onrender.com/live-quiz/create'),
        headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
        body: jsonEncode({'title': _titleController.text.trim(), 'questions': questions}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherLobbyScreen(
          sessionCode: data['session_code'],
          sessionId: data['session_id'],
          title: data['title'],
          questionCount: data['question_count'],
          questions: _questions.map((q) => q.toMap()).toList(),
        )));
      } else {
        _snack('Error: ${jsonDecode(res.body)['detail'] ?? res.body}');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white, elevation: 0,
        title: const Text('Create Quiz', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Tailwind.slate800),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Tailwind.indigo600)))
          else
            TextButton.icon(
              onPressed: _createSession,
              icon: const Icon(Icons.rocket_launch_rounded, color: Tailwind.indigo600, size: 18),
              label: const Text('Go Live', style: TextStyle(color: Tailwind.indigo600, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Tailwind.white, borderRadius: Tailwind.roundedXl, border: Border.all(color: Tailwind.slate200), boxShadow: Tailwind.shadowSm),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold, fontSize: 17),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Quiz Title (e.g. Chapter 3 — Gravitation)',
                  hintStyle: TextStyle(color: Tailwind.slate400, fontWeight: FontWeight.normal, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Questions', style: const TextStyle(color: Tailwind.slate800, fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_questions.length} added', style: const TextStyle(color: Tailwind.slate500, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            ..._questions.asMap().entries.map((e) => _QuestionCard(
              index: e.key, draft: e.value,
              onRemove: () => _removeQuestion(e.key),
              onChanged: () => setState(() {}),
            )),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _addQuestion,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: Tailwind.roundedXl, border: Border.all(color: const Color(0xFFC7D2FE))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5), size: 20),
                    SizedBox(width: 8),
                    Text('Add Question', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createSession,
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
        label: const Text('Generate Session Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── DATA MODEL ───────────────────────────────────────────────────────────────
class _QuestionDraft {
  String questionText = '';
  String type = 'mcq';
  List<String> options = ['', '', '', ''];
  String correctAnswer = '';
  int timerSeconds = 60;          // default 60 s per question
  String timerMode = 'auto';     // 'auto' = auto-advance | 'manual' = teacher clicks

  Map<String, dynamic> toMap() => {
    'question_text': questionText.trim(),
    'question_type': type,
    'options': type == 'mcq' ? options.map((o) => o.trim()).toList() : null,
    'correct_answer': correctAnswer.trim(),
    'timer_seconds': timerSeconds,
    'timer_mode': timerMode,
    'id': '', // teacher display only — real IDs live on the backend
  };
}

// ─── QUESTION CARD WIDGET ─────────────────────────────────────────────────────
class _QuestionCard extends StatefulWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _QuestionCard({required this.index, required this.draft, required this.onRemove, required this.onChanged});
  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final TextEditingController _questionCtrl;
  late final List<TextEditingController> _optionCtrls;
  late final TextEditingController _answerCtrl;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.draft.questionText);
    _optionCtrls = widget.draft.options.map((o) => TextEditingController(text: o)).toList();
    _answerCtrl = TextEditingController(text: widget.draft.correctAnswer);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _toggleType() {
    setState(() {
      widget.draft.type = widget.draft.type == 'mcq' ? 'fill_blank' : 'mcq';
      widget.draft.correctAnswer = '';
      _answerCtrl.clear();
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Tailwind.white, borderRadius: Tailwind.rounded2Xl, border: Border.all(color: Tailwind.slate200), boxShadow: Tailwind.shadowSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                child: Center(child: Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              const Text('Question', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _toggleType,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.draft.type == 'mcq' ? const Color(0xFFEEF2FF) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.draft.type == 'mcq' ? '⊙ MCQ' : '✏ Fill Blank',
                    style: TextStyle(
                      color: widget.draft.type == 'mcq' ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                      fontWeight: FontWeight.bold, fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(onTap: widget.onRemove, child: const Icon(Icons.delete_outline, color: Tailwind.rose500, size: 20)),
            ],
          ),
          const SizedBox(height: 10),
          // ── Timer row: mode toggle + duration chips ───────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.draft.timerMode = widget.draft.timerMode == 'auto' ? 'manual' : 'auto';
                  });
                  widget.onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.draft.timerMode == 'auto' ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.draft.timerMode == 'auto' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.draft.timerMode == 'auto' ? Icons.timer_rounded : Icons.touch_app_rounded,
                        size: 13,
                        color: widget.draft.timerMode == 'auto' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.draft.timerMode == 'auto' ? 'Auto' : 'Manual',
                        style: TextStyle(
                          color: widget.draft.timerMode == 'auto' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.draft.timerMode == 'auto') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [15, 30, 45, 60, 90, 120, 180, 300].map((s) {
                        final isSelected = widget.draft.timerSeconds == s;
                        final String label;
                        if (s < 60) {
                          label = '${s}s';
                        } else if (s % 60 == 0) {
                          label = '${s ~/ 60}m';
                        } else {
                          label = '${s ~/ 60}m${s % 60}s';
                        }
                        return GestureDetector(
                          onTap: () {
                            setState(() => widget.draft.timerSeconds = s);
                            widget.onChanged();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4F46E5) : Tailwind.slate100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Tailwind.slate600,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Question text
          TextField(
            controller: _questionCtrl,
            onChanged: (v) { widget.draft.questionText = v; widget.onChanged(); },
            maxLines: 2,
            style: const TextStyle(color: Tailwind.slate800, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter question text...',
              hintStyle: const TextStyle(color: Tailwind.slate400, fontSize: 13),
              filled: true, fillColor: Tailwind.slate50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.draft.type == 'mcq') ...[
            const Text('OPTIONS  (tap circle to mark correct)', style: TextStyle(color: Tailwind.slate400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...List.generate(4, (i) {
              final optText = _optionCtrls[i].text;
              final isCorrect = widget.draft.correctAnswer.isNotEmpty && widget.draft.correctAnswer == optText && optText.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() { widget.draft.correctAnswer = _optionCtrls[i].text; });
                        widget.onChanged();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFF059669) : Tailwind.slate200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(String.fromCharCode(65 + i),
                          style: TextStyle(color: isCorrect ? Colors.white : Tailwind.slate600, fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _optionCtrls[i],
                        onChanged: (v) {
                          final wasCorrect = widget.draft.correctAnswer == widget.draft.options[i];
                          widget.draft.options[i] = v;
                          if (wasCorrect) { widget.draft.correctAnswer = v; }
                          setState(() {});
                          widget.onChanged();
                        },
                        style: const TextStyle(color: Tailwind.slate800, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Option ${String.fromCharCode(65 + i)}',
                          hintStyle: const TextStyle(color: Tailwind.slate400, fontSize: 13),
                          filled: true,
                          fillColor: isCorrect ? const Color(0xFFECFDF5) : Tailwind.slate50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isCorrect ? const Color(0xFF6EE7B7) : Colors.transparent)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isCorrect ? const Color(0xFF6EE7B7) : Colors.transparent)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (widget.draft.correctAnswer.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 6),
                  Text('Correct: ${widget.draft.correctAnswer}', style: const TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
          ] else ...[
            const Text('CORRECT ANSWER', style: TextStyle(color: Tailwind.slate400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _answerCtrl,
              onChanged: (v) { widget.draft.correctAnswer = v; widget.onChanged(); },
              style: const TextStyle(color: Tailwind.slate800, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Expected answer (case-insensitive match)',
                hintStyle: const TextStyle(color: Tailwind.slate400, fontSize: 13),
                filled: true, fillColor: const Color(0xFFECFDF5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF059669), size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
