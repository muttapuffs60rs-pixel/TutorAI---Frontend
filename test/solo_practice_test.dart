import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/solo_practice_screen.dart';
import 'package:tutor_preethi/screens/live_quiz/live_quiz_entry_screen.dart';

void main() {
  testWidgets('quiz hub offers solo practice without a session code', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LiveQuizEntryScreen()));
    await tester.ensureVisible(find.text('Practise alone'));
    await tester.tap(find.text('Practise alone'));
    await tester.pumpAndSettle();
    expect(find.text('Your pace. No session code.'), findsOneWidget);
    expect(find.text('Session PIN'), findsNothing);
  });
  test('rejects ambiguous or incomplete generated questions', () {
    expect(
      () => PracticeQuestion.fromJson({
        'question': 'Choose one',
        'options': ['A', 'A', 'C', 'D'],
        'correct_answer': 'A',
        'explanation': 'Reason',
      }),
      throwsFormatException,
    );
    expect(
      () => PracticeQuestion.fromJson({
        'question': 'Choose one',
        'options': ['A', 'B', 'C', 'D'],
        'correct_answer': 'E',
        'explanation': 'Reason',
      }),
      throwsFormatException,
    );
  });

  testWidgets(
    'solo practice scores once, reviews answers and retries only mistakes',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SoloPracticeScreen(
            quizLoader: (request) async {
              calls++;
              expect(request['subject'], 'Maths');
              expect(request['grade_level'], 10);
              expect(request['units'], ['Algebra']);
              return const [
                PracticeQuestion(
                  'First question',
                  ['1', '2', '3', '4'],
                  '2',
                  'Two is correct.',
                ),
                PracticeQuestion(
                  'Second question',
                  ['5', '6', '7', '8'],
                  '8',
                  'Eight is correct.',
                ),
              ];
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Algebra');
      await tester.ensureVisible(find.text('Start practice'));
      await tester.tap(find.text('Start practice'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('1'));
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('Not quite. Learn from this one.'), findsOneWidget);
      expect(find.text('✓ Correct answer: 2'), findsOneWidget);
      await tester.ensureVisible(find.text('Next question'));
      await tester.tap(find.text('Next question'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('8'));
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('See results'));
      await tester.tap(find.text('See results'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2 correct'), findsOneWidget);
      await tester.ensureVisible(find.text('Retry missed questions'));
      await tester.tap(find.text('Retry missed questions'));
      await tester.pumpAndSettle();
      expect(find.text('Question 1 of 1'), findsOneWidget);
      expect(find.text('First question'), findsOneWidget);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('validates topic and allows recovery after service failure', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SoloPracticeScreen(
          quizLoader: (_) async {
            calls++;
            throw StateError('Daily quiz limit reached.');
          },
        ),
      ),
    );
    await tester.ensureVisible(find.text('Start practice'));
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a chapter or topic to practise.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(find.byType(TextField), 'Algebra');
    await tester.ensureVisible(find.text('Start practice'));
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    expect(find.text('Daily quiz limit reached.'), findsOneWidget);
    expect(calls, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start practice'),
          )
          .onPressed,
      isNotNull,
    );
  });
}
