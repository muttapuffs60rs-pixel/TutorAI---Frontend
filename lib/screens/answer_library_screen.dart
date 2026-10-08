import 'package:flutter/material.dart';
import '../services/answer_library_service.dart';

class AnswerLibraryScreen extends StatefulWidget {
  final AnswerLibraryService? service;
  const AnswerLibraryScreen({super.key, this.service});

  @override
  State<AnswerLibraryScreen> createState() => _AnswerLibraryScreenState();
}

class _AnswerLibraryScreenState extends State<AnswerLibraryScreen> {
  late final AnswerLibraryService _service =
      widget.service ?? AnswerLibraryService();
  List<Map<String, dynamic>> _answers = [];
  String _status = 'pending';
  String? _error;
  bool _loading = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.list(_status, _offset);
      if (mounted) setState(() => _answers = rows);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not load the library. Check your connection and administrator access.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Answer library'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Review explanations against the textbook before approving them for students. Reported answers return here for review.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Show: '),
              DropdownButton<String>(
                value: _status,
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _status = value;
                          _offset = 0;
                        });
                        _load();
                      },
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Needs review'),
                  ),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _answers.isEmpty
              ? const Center(child: Text('No answers in this list yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _answers.length,
                  itemBuilder: (context, index) {
                    final answer = _answers[index];
                    return Card(
                      child: ListTile(
                        title: Text(answer['question'] as String),
                        subtitle: Text(
                          'Class ${answer['grade_level']} · ${answer['subject']}\n'
                          '${answer['syllabus_version']} · ${answer['language']} · ${answer['report_count'] ?? 0} reports',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnswerReviewScreen(
                                answer: answer,
                                service: _service,
                              ),
                            ),
                          );
                          if (changed == true && mounted) _load();
                        },
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _loading || _offset == 0
                    ? null
                    : () {
                        _offset -= 30;
                        _load();
                      },
                child: const Text('Previous'),
              ),
              Text('Page ${_offset ~/ 30 + 1}'),
              TextButton(
                onPressed: _loading || _answers.length < 30
                    ? null
                    : () {
                        _offset += 30;
                        _load();
                      },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AnswerReviewScreen extends StatefulWidget {
  final Map<String, dynamic> answer;
  final AnswerLibraryService service;
  const AnswerReviewScreen({
    super.key,
    required this.answer,
    required this.service,
  });

  @override
  State<AnswerReviewScreen> createState() => _AnswerReviewScreenState();
}

class _AnswerReviewScreenState extends State<AnswerReviewScreen> {
  late final _answer = TextEditingController(
    text: widget.answer['answer'] as String,
  );
  late final _chapter = TextEditingController(
    text: widget.answer['chapter'] as String? ?? '',
  );
  late final _reference = TextEditingController(
    text: widget.answer['source_reference'] as String? ?? '',
  );
  late final _note = TextEditingController(
    text: widget.answer['review_note'] as String? ?? '',
  );
  bool _accuracy = false;
  bool _privacy = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _answer.dispose();
    _chapter.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(String status) async {
    if (_answer.text.trim().isEmpty ||
        (status == 'approved' &&
            (!_accuracy ||
                !_privacy ||
                _chapter.text.trim().isEmpty ||
                _reference.text.trim().isEmpty))) {
      setState(
        () => _error =
            'Approval requires an answer, chapter, textbook reference, and both review checks.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.review(widget.answer['id'] as String, {
        'status': status,
        'answer': _answer.text.trim(),
        'chapter': _chapter.text.trim(),
        'source_reference': _reference.text.trim(),
        'review_note': _note.text.trim(),
        'accuracy_checked': _accuracy,
        'privacy_checked': _privacy,
        'expected_updated_at': widget.answer['updated_at'],
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not save. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review answer')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.answer['question'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Class ${widget.answer['grade_level']} · ${widget.answer['subject']} · ${widget.answer['language']}\n'
              '${widget.answer['board']} · ${widget.answer['syllabus_version']}',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _answer,
              enabled: !_saving,
              minLines: 6,
              maxLines: 16,
              maxLength: 16000,
              decoration: const InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _chapter,
              enabled: !_saving,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Chapter'),
            ),
            TextField(
              controller: _reference,
              enabled: !_saving,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Textbook edition, section and page',
              ),
            ),
            TextField(
              controller: _note,
              enabled: !_saving,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Review notes'),
            ),
            CheckboxListTile(
              value: _accuracy,
              onChanged: _saving ? null : (v) => setState(() => _accuracy = v!),
              title: const Text(
                'I checked correctness, syllabus, language, and that the answer is complete.',
              ),
            ),
            CheckboxListTile(
              value: _privacy,
              onChanged: _saving ? null : (v) => setState(() => _privacy = v!),
              title: const Text(
                'The question and answer contain no personal information and make sense without earlier messages.',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _saving ? null : () => _save('approved'),
                  child: const Text('Approve answer'),
                ),
                OutlinedButton(
                  onPressed: _saving ? null : () => _save('pending'),
                  child: const Text('Keep unpublished'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => _save('rejected'),
                  child: const Text('Reject'),
                ),
              ],
            ),
            if (_saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
  );
}
