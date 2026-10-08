import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/live_quiz/live_quiz_entry_screen.dart';

void main() {
  testWidgets('practice quiz is reachable from quiz modes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LiveQuizEntryScreen()));
    await tester.ensureVisible(find.text('Practice on my own'));
    await tester.tap(find.text('Practice on my own'));
    await tester.pumpAndSettle();
    expect(find.text('Custom Quiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
