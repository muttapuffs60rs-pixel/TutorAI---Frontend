import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/question_photo_review.dart';

void main() {
  for (final entry in {
    'Use full photo': QuestionPhotoChoice.fullPhoto,
    'Crop photo': QuestionPhotoChoice.crop,
    'Cancel': null,
  }.entries) {
    testWidgets('photo review: ${entry.key}', (tester) async {
      QuestionPhotoChoice? result;
      final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6o0kAAAAASUVORK5CYII=');
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
        TextButton(onPressed: () async {
          result = await showDialog<QuestionPhotoChoice>(context: context,
              builder: (_) => QuestionPhotoReview(bytes: bytes));
        }, child: const Text('Attach')))));
      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(result, entry.value);
      expect(find.text('Check your question photo'), findsNothing);
    });
  }
}
