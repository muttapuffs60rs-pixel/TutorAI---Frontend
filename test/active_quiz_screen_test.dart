import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/active_quiz_screen.dart';

void main() {
  testWidgets('generated options render, score, and advance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveQuizScreen(
          questions: [
            {
              'question': 'Which is a planet?',
              'options': ['Mars', 'Moon', 'Sun', 'Polaris'],
              'correct_answer': 'Mars',
              'explanation': 'Mars is a planet.',
            },
          ],
        ),
      ),
    );
    for (final option in ['Mars', 'Moon', 'Sun', 'Polaris']) {
      expect(find.text(option), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Mars'));
    await tester.pump();
    await tester.ensureVisible(find.text('Check Answer'));
    await tester.tap(find.text('Check Answer'));
    await tester.pump();
    expect(find.text('✅ Correct!'), findsOneWidget);
    expect(find.text('Akka says: Mars is a planet.'), findsOneWidget);
    await tester.ensureVisible(find.text('Next Question'));
    await tester.tap(find.text('Next Question'));
    await tester.pumpAndSettle();
    expect(find.text('You scored 1 out of 1!'), findsOneWidget);
  });
}
