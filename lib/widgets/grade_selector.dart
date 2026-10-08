import 'package:flutter/material.dart';
import '../constants.dart';

/// A wrapping selector keeps all supported classes usable on small screens.
class GradeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const GradeSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final grade in supportedGrades)
        ChoiceChip(
          label: Text('Class $grade'),
          selected: value == grade,
          onSelected: (_) => onChanged(grade),
        ),
    ],
  );
}
