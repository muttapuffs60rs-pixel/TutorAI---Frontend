import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/legal_policy_screen.dart';

void main() {
  testWidgets('Policies are accessible without signing in and cross-link',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LegalPolicyLinks()),
    ));
    await tester.tap(find.text('Terms and Conditions'));
    await tester.pumpAndSettle();
    expect(find.text('1. Using Arivora'), findsOneWidget);
    final refundLink = find.text('Read Cancellation and Refund Policy');
    await tester.scrollUntilVisible(refundLink, 400,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(refundLink);
    await tester.pumpAndSettle();
    expect(find.text('1. Cancelling a purchase or future access'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Terms and Conditions'), findsOneWidget);
  });

  testWidgets('Refund policy remains readable on a narrow screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.5),
        ),
        child: child!,
      ),
      home: const LegalPolicyScreen(policy: LegalPolicy.refunds),
    ));
    await tester.scrollUntilVisible(find.text('Contact support'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Contact support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
