import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/splash_screen.dart';

void main() {
  testWidgets('Company splash fits a small screen and continues to the app',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: const SplashScreen(),
      routes: {
        '/auth_gate': (_) => const Scaffold(body: Text('App entry')),
      },
    ));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('AuxiumSoft'), findsOneWidget);
    expect(find.text('An AuxiumSoft product'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.text('App entry'), findsOneWidget);
  });

  testWidgets('Leaving the splash cancels delayed navigation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const MaterialApp(home: Text('Another screen')));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Another screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
