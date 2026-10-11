import 'package:flutter/material.dart';

const boardNames = {'tn': 'Tamil Nadu State Board', 'cbse': 'CBSE'};

String? savedBoard(Map<String, dynamic>? metadata) {
  final value = metadata?['education_board'];
  return boardNames.containsKey(value) ? value as String : null;
}

class BoardSelectionScreen extends StatefulWidget {
  final String? initialBoard;
  final Future<void> Function(String) onSave;
  final bool changing;
  const BoardSelectionScreen({
    super.key,
    this.initialBoard,
    required this.onSave,
    this.changing = false,
  });

  @override
  State<BoardSelectionScreen> createState() => _BoardSelectionScreenState();
}

class _BoardSelectionScreenState extends State<BoardSelectionScreen> {
  late String? _board = widget.initialBoard;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_board!);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not save your board. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.changing && !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.changing ? 'Change board' : 'Welcome to Arivora'),
        automaticallyImplyLeading: widget.changing && !_saving,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Select your board',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We will remember your board for next time. You can change it from the menu anytime.',
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _board,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Board'),
                    hint: const Text('Select board'),
                    items: boardNames.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _board = value),
                  ),
                  if (_board == 'cbse')
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'English-medium NCERT textbooks for Classes 6–12.',
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _board == null || _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Continue to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
