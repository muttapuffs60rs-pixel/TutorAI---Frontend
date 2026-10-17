import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../main.dart';

class PracticeQuestion {
  final String question, answer, explanation;
  final List<String> options;
  const PracticeQuestion(
    this.question,
    this.options,
    this.answer,
    this.explanation,
  );

  factory PracticeQuestion.fromJson(Map<String, dynamic> data) {
    final options = List<String>.from(data['options'] as List);
    final question = data['question'] as String;
    final answer = data['correct_answer'] as String;
    final explanation = data['explanation'] as String;
    if (question.trim().isEmpty ||
        options.length != 4 ||
        options.toSet().length != 4 ||
        options.any((o) => o.trim().isEmpty) ||
        !options.contains(answer) ||
        explanation.trim().isEmpty) {
      throw const FormatException('Invalid practice question');
    }
    return PracticeQuestion(question, options, answer, explanation);
  }
}

Future<List<PracticeQuestion>> loadPracticeQuiz(
  Map<String, dynamic> request,
) async {
  final token = supabase.auth.currentSession?.accessToken;
  if (token == null) throw StateError('Please sign in again.');
  const backend = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://akka-tutor-backend.onrender.com',
  );
  final response = await http
      .post(
        Uri.parse('$backend/generate-quiz'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request),
      )
      .timeout(const Duration(seconds: 90));
  if (response.statusCode == 403) {
    throw StateError(
      'Your daily quiz limit has been reached, or your account does not have access. Try again tomorrow or contact support.',
    );
  }
  if (response.statusCode == 401) throw StateError('Please sign in again.');
  if (response.statusCode != 200) {
    throw StateError('Could not create your quiz. Please try again.');
  }
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final questions = (data['questions'] as List)
      .map(
        (q) => PracticeQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
      )
      .toList();
  if (questions.length != request['num_questions']) {
    throw const FormatException('Incomplete practice quiz');
  }
  return questions;
}

class SoloPracticeScreen extends StatefulWidget {
  final Future<List<PracticeQuestion>> Function(Map<String, dynamic>)
  quizLoader;
  const SoloPracticeScreen({super.key, this.quizLoader = loadPracticeQuiz});
  @override
  State<SoloPracticeScreen> createState() => _SoloPracticeScreenState();
}

class _SoloPracticeScreenState extends State<SoloPracticeScreen> {
  final _topic = TextEditingController();
  int _grade = 10, _count = 5, _index = 0;
  String _subject = 'Maths';
  bool _loading = false, _finished = false;
  String? _error;
  List<PracticeQuestion> _questions = [];
  final Map<int, String> _answers = {};

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_loading) return;
    if (_topic.text.trim().isEmpty) {
      setState(() => _error = 'Enter a chapter or topic to practise.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await widget.quizLoader({
        'grade_level': _grade,
        'subject': _subject,
        'units': [_topic.text.trim()],
        'num_questions': _count,
      });
      if (questions.isEmpty) throw const FormatException('Empty quiz');
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _answers.clear();
        _index = 0;
        _finished = false;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not create your quiz. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _score =>
      _answers.entries.where((e) => _questions[e.key].answer == e.value).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practise alone')),
      body: SafeArea(
        child: SingleChildScrollView(
          key: ValueKey(
            _questions.isEmpty
                ? 'setup'
                : _finished
                ? 'results'
                : 'question-$_index',
          ),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _questions.isEmpty
                    ? _setup()
                    : _finished
                    ? _results()
                    : _question(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _setup() => [
    const Text(
      'Your pace. No session code.',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 12),
    const Text(
      'Choose a topic, answer each question, and learn from the explanations. No timer or leaderboard.',
    ),
    const SizedBox(height: 12),
    const Text(
      'Tamil Nadu State Board · Classes 6–12',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const Text(
      'Solo practice currently uses State Board textbooks. CBSE practice is not available here yet.',
    ),
    const SizedBox(height: 20),
    DropdownButtonFormField<int>(
      initialValue: _grade,
      decoration: const InputDecoration(labelText: 'Class'),
      items: supportedGrades
          .map((g) => DropdownMenuItem(value: g, child: Text('Class $g')))
          .toList(),
      onChanged: _loading
          ? null
          : (g) => setState(() {
              _grade = g!;
              _subject = subjectsForBoard('tn', _grade).first['name'] as String;
              _topic.clear();
            }),
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      key: ValueKey(_grade),
      initialValue: _subject,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Subject'),
      items: subjectsForBoard('tn', _grade)
          .map(
            (s) => DropdownMenuItem(
              value: s['name'] as String,
              child: Text(s['name'] as String),
            ),
          )
          .toList(),
      onChanged: _loading
          ? null
          : (s) => setState(() {
              _subject = s!;
              _topic.clear();
            }),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _topic,
      enabled: !_loading,
      maxLength: 150,
      decoration: const InputDecoration(
        labelText: 'Chapter or topic',
        hintText: 'e.g. Quadratic equations',
      ),
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<int>(
      initialValue: _count,
      decoration: const InputDecoration(labelText: 'Questions'),
      items: [3, 5, 10]
          .map((n) => DropdownMenuItem(value: n, child: Text('$n questions')))
          .toList(),
      onChanged: _loading ? null : (n) => setState(() => _count = n!),
    ),
    const SizedBox(height: 20),
    const Text(
      'Up to 5 generated quizzes per day. Retrying missed questions uses the same quiz. AI-generated questions can contain mistakes; check your textbook if unsure.',
    ),
    if (_error != null)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          _error!,
          semanticsLabel: _error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: _loading ? null : _start,
      child: Text(_loading ? 'Creating your quiz…' : 'Start practice'),
    ),
    if (_loading)
      const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
  ];

  List<Widget> _question() {
    final q = _questions[_index];
    final selected = _answers[_index];
    return [
      Text('Class $_grade · $_subject · ${_topic.text.trim()}'),
      const SizedBox(height: 12),
      Text(
        'Question ${_index + 1} of ${_questions.length}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      LinearProgressIndicator(value: (_index + 1) / _questions.length),
      const SizedBox(height: 24),
      SelectableText(
        q.question,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 20),
      ...q.options.map(
        (o) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton(
            onPressed: selected == null
                ? () => setState(() => _answers[_index] = o)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                selected == null
                    ? o
                    : '${o == q.answer
                          ? '✓ Correct answer: '
                          : o == selected
                          ? 'Your answer: '
                          : ''}$o',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
      if (selected != null) ...[
        Text(
          selected == q.answer ? 'Correct!' : 'Not quite. Learn from this one.',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SelectableText(q.explanation),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => setState(() {
            if (_index == _questions.length - 1) {
              _finished = true;
            } else {
              _index++;
            }
          }),
          child: Text(
            _index == _questions.length - 1 ? 'See results' : 'Next question',
          ),
        ),
      ],
    ];
  }

  List<Widget> _results() => [
    const Text(
      'Practice complete',
      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 12),
    Text(
      '$_score / ${_questions.length} correct',
      style: const TextStyle(fontSize: 24),
    ),
    const Text(
      'Review the explanations below. Results stay in this session and are not saved to your profile.',
    ),
    const SizedBox(height: 16),
    ..._questions.asMap().entries.map(
      (e) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.key + 1}. ${e.value.question}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Your answer: ${_answers[e.key]}'),
              Text('Correct answer: ${e.value.answer}'),
              Text(e.value.explanation),
            ],
          ),
        ),
      ),
    ),
    if (_score < _questions.length)
      OutlinedButton(
        onPressed: () => setState(() {
          _questions = _questions
              .asMap()
              .entries
              .where((e) => _answers[e.key] != e.value.answer)
              .map((e) => e.value)
              .toList();
          _answers.clear();
          _index = 0;
          _finished = false;
        }),
        child: const Text('Retry missed questions'),
      ),
    FilledButton(
      onPressed: () => setState(() {
        _questions = [];
        _answers.clear();
        _finished = false;
      }),
      child: const Text('Choose another topic'),
    ),
  ];
}
