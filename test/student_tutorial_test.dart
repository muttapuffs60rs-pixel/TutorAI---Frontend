import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutor_preethi/screens/student_tutorial.dart';

void main() {
  test('completion is remembered separately per account', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await StudentTutorial.needsIntroduction('a'), isTrue);
    await StudentTutorial.remember('a');
    expect(await StudentTutorial.needsIntroduction('a'), isFalse);
    expect(await StudentTutorial.needsIntroduction('b'), isTrue);
  });
  testWidgets('tour navigates, completes, and replays at phone width', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => StudentTutorial.show(context), child: const Text('Open tour'))))));
    await tester.tap(find.text('Open tour'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 6'), findsOneWidget);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 6'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.textContaining('learn').last);
    await tester.tap(find.textContaining('learn').last);
    await tester.pumpAndSettle();
    expect(find.byType(StudentTutorial), findsNothing);
    await tester.tap(find.text('Open tour'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 6'), findsOneWidget);
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentTutorial), findsNothing);
  });
}
