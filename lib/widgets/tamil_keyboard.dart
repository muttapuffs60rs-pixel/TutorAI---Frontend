import 'package:flutter/material.dart';

/// Keep edits on grapheme boundaries, including Tamil vowel signs and emoji.
void editTamilDraft(
  TextEditingController controller,
  String text, {
  bool backspace = false,
}) {
  final value = controller.value;
  final selection = value.selection;
  var start = selection.isValid
      ? selection.start.clamp(0, value.text.length)
      : value.text.length;
  var end = selection.isValid
      ? selection.end.clamp(0, value.text.length)
      : value.text.length;
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
  const TamilKeyboard({
    super.key,
    required this.controller,
    required this.onDone,
  });

  @override
  State<TamilKeyboard> createState() => _TamilKeyboardState();
}

class _TamilKeyboardState extends State<TamilKeyboard> {
  String? consonant;
  int group = 0;
  static const vowels = [
    'அ',
    'ஆ',
    'இ',
    'ஈ',
    'உ',
    'ஊ',
    'எ',
    'ஏ',
    'ஐ',
    'ஒ',
    'ஓ',
    'ஔ',
    'ஃ',
  ];
  static const consonants = [
    'க',
    'ங',
    'ச',
    'ஞ',
    'ட',
    'ண',
    'த',
    'ந',
    'ப',
    'ம',
    'ய',
    'ர',
    'ல',
    'வ',
    'ழ',
    'ள',
    'ற',
    'ன',
    'ஜ',
    'ஷ',
    'ஸ',
    'ஹ',
    'க்ஷ',
  ];
  static const signs = [
    '',
    'ா',
    'ி',
    'ீ',
    'ு',
    'ூ',
    'ெ',
    'ே',
    'ை',
    'ொ',
    'ோ',
    'ௌ',
    '்',
  ];
  static const symbols = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    '?',
    '.',
    ',',
    '!',
    'ஸ்ரீ',
  ];

  void insert(String letter) {
    editTamilDraft(widget.controller, letter);
    if (consonant != null) setState(() => consonant = null);
  }

  @override
  Widget build(BuildContext context) {
    final forms = consonant != null;
    final letters = forms
        ? signs.map((sign) => '$consonant$sign').toList()
        : group == 0
        ? consonants
        : group == 1
        ? vowels
        : symbols;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'தமிழில் எழுதுங்கள்',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: widget.onDone, child: const Text('Done')),
              ],
            ),
            TextField(
              controller: widget.controller,
              readOnly: true,
              showCursor: true,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'உங்கள் கேள்வி / Your question',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            if (forms)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => consonant = null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('எழுத்துகள்'),
                  ),
                  Expanded(
                    child: Text(
                      '$consonant — வடிவத்தைத் தொடவும்',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  for (final tab in [
                    (0, 'க எழுத்துகள்'),
                    (1, 'அ உயிர்'),
                    (2, '123 / ?'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          key: ValueKey('tamil-tab-${tab.$1}'),
                          label: Text(tab.$2),
                          labelPadding: EdgeInsets.zero,
                          showCheckmark: false,
                          selected: group == tab.$1,
                          onSelected: (_) => setState(() => group = tab.$1),
                        ),
                      ),
                    ),
                ],
              ),
            if (!forms)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  group == 0
                      ? 'முதலில் எழுத்தைத் தொடவும் · க → கி, கு, க்'
                      : 'எழுத வேண்டிய எழுத்தைத் தொடவும்',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 350 ? 5 : 6;
                  return GridView.builder(
                    key: ValueKey('tamil-grid-$group-$consonant'),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 50,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: letters.length,
                    itemBuilder: (context, index) {
                      final letter = letters[index];
                      final choosing = !forms && group == 0;
                      return OutlinedButton(
                        key: ValueKey(
                          '${choosing ? 'choose' : 'insert'}-$letter',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => choosing
                            ? setState(() => consonant = letter)
                            : insert(letter),
                        child: Text(
                          letter,
                          style: const TextStyle(fontSize: 22),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => editTamilDraft(widget.controller, ' '),
                    child: const Text('Space / இடைவெளி'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete previous letter',
                  onPressed: () =>
                      editTamilDraft(widget.controller, '', backspace: true),
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
