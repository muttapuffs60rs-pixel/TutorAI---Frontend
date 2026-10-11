import 'package:flutter/material.dart';
import 'package:tutor_preethi/screens/subject_selection_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/constants.dart';

void main() {
  testWidgets('CBSE Class 9 presents NCERT subjects only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SubjectSelectionScreen(board:'cbse')));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 9').last);
    await tester.pumpAndSettle();
    expect(find.text('Tamil'), findsNothing);
    expect(find.text('Mathematics'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Social');
    await tester.pumpAndSettle();
    expect(find.text('Social Science'), findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  test('Class 9 catalogues stay board-specific', () {
    final tn = subjectsForBoard('tn', 9).map((s) => s['name']).toList();
    final cbse = subjectsForBoard('cbse', 9).map((s) => s['name']).toList();
    expect(tn, contains('Tamil'));
    expect(cbse, isNot(contains('Tamil')));
    expect(cbse, contains('Mathematics'));
    expect(cbse, contains('Social Science'));
    expect(cbse, isNot(contains('Vocational')));
    expect(subjectsForBoard('unknown', 9), isEmpty);
  });
  test('CBSE has separate catalogues for every supported class', () {
    for (final grade in supportedGrades) {
      expect(subjectsForBoard('cbse', grade), isNotEmpty);
    }
  });
}
