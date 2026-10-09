import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/live_quiz/live_quiz_entry_screen.dart';

void main() {
  testWidgets('live classroom keeps teacher and student entry points', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LiveQuizEntryScreen()));
    expect(find.text("I'm a Teacher"), findsOneWidget);
    expect(find.text("I'm a Student"), findsOneWidget);
    expect(find.text('Practice on my own'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
