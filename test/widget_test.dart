import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/subject_picker_sheet.dart';

void main() {
  testWidgets('Class 6 selection sends its own grade and subject', (tester) async {
    int? grade;
    String? subject;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubjectPickerSheet(
      initialGrade: 6,
      onSubjectSelected: (g, s) { grade = g; subject = s; },
    ))));
    expect(find.textContaining('Terms 1, 2 and 3 textbooks'), findsOneWidget);
    await tester.tap(find.text('Tamil'));
    expect(grade, 6);
    expect(subject, 'Tamil');
  });

  testWidgets('Unloaded grades cannot open tutoring or inherit Class 12 subjects', (tester) async {
    var selected = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubjectPickerSheet(
      initialGrade: 6, onSubjectSelected: (_, _) => selected = true,
    ))));
    for (final grade in [7, 8, 9]) {
      await tester.tap(find.text('Class $grade'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Class $grade textbooks are coming soon'), findsOneWidget);
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Tamil')).enabled, false);
      await tester.tap(find.text('Tamil'));
      expect(selected, false);
    }
    await tester.tap(find.text('Class 11'));
    await tester.pumpAndSettle();
    expect(find.text('Chemistry Volume 1'), findsNothing);
    expect(find.text('Textbooks coming soon'), findsOneWidget);
  });

  testWidgets('All seven grade choices fit a phone width', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubjectPickerSheet(
      initialGrade: 12, onSubjectSelected: (_, _) {},
    ))));
    for (final grade in [6, 7, 8, 9, 10, 11, 12]) {
      expect(find.text('Class $grade'), findsOneWidget);
    }
    await tester.tap(find.text('Class 6'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
