import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/subject_selection_screen.dart';

void main() {
  testWidgets('Tuition uses saved board and waits for class', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SubjectSelectionScreen(board: 'tn')),
    );
    expect(find.text('Tamil Nadu State Board'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Select class first'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 6').last);
    await tester.pumpAndSettle();
    expect(find.text('Tamil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
