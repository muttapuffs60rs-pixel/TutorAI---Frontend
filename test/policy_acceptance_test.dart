import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/policy_acceptance_gate.dart';

void main() {
  test('both current policy versions are required', () {
    expect(hasAcceptedPolicies(null), false);
    expect(
      hasAcceptedPolicies({'terms_accepted_version': acceptanceVersion}),
      false,
    );
    expect(
      hasAcceptedPolicies({
        'terms_accepted_version': acceptanceVersion,
        'refunds_accepted_version': 'old',
      }),
      false,
    );
    expect(
      hasAcceptedPolicies({
        'terms_accepted_version': acceptanceVersion,
        'refunds_accepted_version': acceptanceVersion,
      }),
      true,
    );
  });
  testWidgets(
    'both consents required, policies readable, save failures stay gated',
    (tester) async {
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PolicyAcceptanceScreen(
            onAccept: () async {
              saves++;
              throw Exception('offline');
            },
            onSignOut: () async {},
          ),
        ),
      );
      FilledButton button() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept and continue'),
      );
      expect(button().onPressed, isNull);
      await tester.tap(find.text('Read Terms and Conditions'));
      await tester.pumpAndSettle();
      expect(find.text('Last updated: 14 October 2026'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.pump();
      expect(button().onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.pump();
      expect(button().onPressed, isNotNull);
      await tester.ensureVisible(find.text('Accept and continue'));
      await tester.tap(find.text('Accept and continue'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(
        find.text('Could not save your acceptance. Please try again.'),
        findsOneWidget,
      );
    },
  );
}
