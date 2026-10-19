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
  testWidgets('tour navigates, completes, and replays at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => StudentTutorial.show(context),
              child: const Text('Open tour'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open tour'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 7'), findsOneWidget);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 7'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
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
    expect(find.text('Step 1 of 7'), findsOneWidget);
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentTutorial), findsNothing);
  });

  test(
    'students who saw the old tour receive the improved guide once',
    () async {
      SharedPreferences.setMockInitialValues({'student_tutorial_v2_a': true});
      expect(await StudentTutorial.needsIntroduction('a'), isTrue);
      await StudentTutorial.remember('a');
      expect(await StudentTutorial.needsIntroduction('a'), isFalse);
    },
  );

  for (final size in [const Size(360, 640), const Size(740, 360)]) {
    testWidgets('navigation stays visible at large text on $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(body: StudentTutorial(onClose: () {})),
        ),
      );
      for (var i = 0; i < 6; i++) {
        expect(find.text('Step ${i + 1} of 7'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Do not scroll: navigation must remain available on long tutorial pages.
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Let’s learn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('guide separates solo practice from classroom joining', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StudentTutorial(onClose: () {})),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Practise at your own pace'), findsOneWidget);
    expect(find.text('Home → Quizzes → Practise alone'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Join a live classroom'), findsOneWidget);
    expect(find.text('Home → Quizzes → I’m a Student'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
