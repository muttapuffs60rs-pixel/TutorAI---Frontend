import 'dart:typed_data';
import 'package:flutter/material.dart';

enum QuestionPhotoChoice { fullPhoto, crop }

/// Keep the whole question by default; cropping is an explicit alternative.
class QuestionPhotoReview extends StatelessWidget {
  final Uint8List bytes;
  const QuestionPhotoReview({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Check your question photo'),
    content: SizedBox(
      width: 480,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Keep all symbols, labels and measurements in the photo.'),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, QuestionPhotoChoice.crop),
          child: const Text('Crop photo')),
      FilledButton(onPressed: () => Navigator.pop(context, QuestionPhotoChoice.fullPhoto),
          child: const Text('Use full photo')),
    ],
  );
}
