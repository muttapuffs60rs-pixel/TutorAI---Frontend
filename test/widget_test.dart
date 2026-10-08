import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/subject_picker_sheet.dart';
import 'package:tutor_preethi/constants.dart';

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

  testWidgets('New middle grades send their own grade and subject', (tester) async {
    int? selectedGrade;
    String? selectedSubject;
    for (final grade in [7, 8, 9]) {
      await tester.pumpWidget(MaterialApp(key: ValueKey(grade), home: Scaffold(body: SubjectPickerSheet(
        initialGrade: grade, onSubjectSelected: (g, s) { selectedGrade = g; selectedSubject = s; },
      ))));
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Tamil')).enabled, true);
      await tester.tap(find.text('Tamil'));
      expect(selectedGrade, grade);
      expect(selectedSubject, 'Tamil');
    }
  });

  test('Class 11 uses its verified catalogue, not Class 12 subjects', () {
    final names = subjectsForGrade(11).map((s) => s['name']).toList();
    expect(names, containsAll(['Zoology', 'Basic Electronics Engineering', 'Botany Volume 1', 'Communicative English']));
    expect(names, isNot(contains('Basic Mechanical Engineering')));
    expect(names, isNot(contains('Bio Botany')));
    expect(names, isNot(contains('Auditing')));
    expect(names.toSet().length, names.length);
    expect(gradeHasTextbooks(11), true);
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
