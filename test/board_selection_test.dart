import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/board_selection_screen.dart';

void main() {
  test('Only supported account boards skip onboarding', () {
    expect(savedBoard(null), isNull);
    expect(savedBoard({'education_board': 'unknown'}), isNull);
    expect(savedBoard({'education_board': 'tn'}), 'tn');
    expect(savedBoard({'education_board': 'cbse'}), 'cbse');
  });

  testWidgets('Board must be selected; failed saves can be retried', (
    tester,
  ) async {
    var attempts = 0;
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: BoardSelectionScreen(
          onSave: (board) async {
            attempts++;
            if (attempts == 1) throw Exception('offline');
            saved = board;
          },
        ),
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamil Nadu State Board').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to Home'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(
      find.text('Could not save your board. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue to Home'));
    await tester.pumpAndSettle();
    expect(saved, 'tn');
    expect(attempts, 2);
  });

  testWidgets('Change board preselects saved value and explains CBSE medium', (
    tester,
  ) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: BoardSelectionScreen(
          changing: true,
          initialBoard: 'cbse',
          onSave: (board) async {
            saved = board;
          },
        ),
      ),
    );
    expect(find.text('CBSE'), findsOneWidget);
    expect(
      find.textContaining('English-medium NCERT textbooks'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue to Home'));
    await tester.pumpAndSettle();
    expect(saved, 'cbse');
  });
}
