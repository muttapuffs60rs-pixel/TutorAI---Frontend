import 'package:flutter/material.dart';

/// Keep edits on grapheme boundaries, including Tamil vowel signs and emoji.
void editTamilDraft(TextEditingController controller, String text, {bool backspace = false}) {
  final value = controller.value;
  final selection = value.selection;
  var start = selection.isValid ? selection.start.clamp(0, value.text.length) : value.text.length;
  var end = selection.isValid ? selection.end.clamp(0, value.text.length) : value.text.length;
  final boundaries = <int>[0];
  for (final letter in value.text.characters) {
    boundaries.add(boundaries.last + letter.length);
  }
  if (start == end) {
    start = end = boundaries.firstWhere((offset) => offset >= start);
  } else {
    start = boundaries.lastWhere((offset) => offset <= start);
    end = boundaries.firstWhere((offset) => offset >= end);
  }
  if (backspace && start == end && start > 0) {
    start = boundaries.lastWhere((offset) => offset < start);
  }
  final replacement = backspace ? '' : text;
  controller.value = TextEditingValue(
    text: value.text.replaceRange(start, end, replacement),
    selection: TextSelection.collapsed(offset: start + replacement.length),
  );
}

class TamilKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onDone;
  const TamilKeyboard({super.key, required this.controller, required this.onDone});

  @override
  State<TamilKeyboard> createState() => _TamilKeyboardState();
}

class _TamilKeyboardState extends State<TamilKeyboard> {
  String consonant = 'க';
  static const vowels = ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ', 'ஃ'];
  static const consonants = ['க', 'ங', 'ச', 'ஞ', 'ட', 'ண', 'த', 'ந', 'ப', 'ம', 'ய', 'ர', 'ல', 'வ', 'ழ', 'ள', 'ற', 'ன', 'ஜ', 'ஷ', 'ஸ', 'ஹ', 'க்ஷ'];
  static const signs = ['', 'ா', 'ி', 'ீ', 'ு', 'ூ', 'ெ', 'ே', 'ை', 'ொ', 'ோ', 'ௌ', '்'];

  Widget letterKey(String letter) => OutlinedButton(
    key: ValueKey('insert-$letter'),
    style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 10)),
    onPressed: () => editTamilDraft(widget.controller, letter),
    child: Text(letter, style: const TextStyle(fontSize: 19)),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Expanded(child: Text('தமிழ் keyboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            TextButton(onPressed: widget.onDone, child: const Text('Done')),
          ]),
          TextField(
            controller: widget.controller,
            readOnly: true,
            showCursor: true,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Your question / உங்கள் கேள்வி', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vowels / உயிரெழுத்துகள்'),
              Wrap(spacing: 4, runSpacing: 4, children: vowels.map(letterKey).toList()),
              const SizedBox(height: 12),
              const Text('1. Choose a consonant / மெய் எழுத்தைத் தேர்ந்தெடுக்கவும்'),
              Wrap(spacing: 4, children: consonants.map((letter) => ChoiceChip(
                key: ValueKey('choose-$letter'),
                label: Text(letter, style: const TextStyle(fontSize: 18)),
                selected: consonant == letter,
                onSelected: (_) => setState(() => consonant = letter),
              )).toList()),
              const SizedBox(height: 8),
              const Text('2. Tap a letter to type / எழுத வேண்டிய எழுத்தைத் தொடவும்'),
              Wrap(spacing: 4, runSpacing: 4, children: signs.map((sign) => letterKey('$consonant$sign')).toList()),
              const SizedBox(height: 12),
              Wrap(spacing: 4, runSpacing: 4, children: ['ஸ்ரீ', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '?', '.', ',', '!'].map(letterKey).toList()),
            ],
          ))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => editTamilDraft(widget.controller, ' '),
              child: const Text('Space / இடைவெளி'),
            )),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Delete previous letter',
              onPressed: () => editTamilDraft(widget.controller, '', backspace: true),
              icon: const Icon(Icons.backspace_outlined),
            ),
          ]),
        ],
      ),
    ),
  );
}
