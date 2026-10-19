import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/Support_screen.dart';
import 'package:tutor_preethi/screens/legal_policy_screen.dart';

void main() {
  testWidgets(
    'refund contact stays in app and copies address and payment template',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(home: LegalPolicyScreen(policy: LegalPolicy.refunds)),
      );
      await tester.ensureVisible(find.text('Contact support'));
      await tester.tap(find.text('Contact support'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportScreen), findsOneWidget);
      expect(find.text('Payment or refund request'), findsOneWidget);
      await tester.tap(find.text('Copy email address'));
      await tester.pumpAndSettle();
      expect(copied, SupportScreen.email);
      await tester.ensureVisible(find.text('Copy request template'));
      await tester.tap(find.text('Copy request template'));
      await tester.pumpAndSettle();
      expect(copied, contains('Payment / order ID:'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LegalPolicyScreen), findsOneWidget);
    },
  );
  testWidgets(
    'clipboard failure leaves selectable contact information at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'unavailable');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const SupportScreen(),
        ),
      );
      await tester.ensureVisible(find.text('Copy email address'));
      await tester.tap(find.text('Copy email address'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Copy was unavailable.'), findsOneWidget);
      expect(
        find.widgetWithText(SelectableText, SupportScreen.email),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
