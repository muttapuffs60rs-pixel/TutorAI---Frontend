import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/referrals_screen.dart';

void main() {
  testWidgets(
    'referral page applies code and shows private reward state on phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? applied;
      bool claimed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ReferralsScreen(
            load: () async => {
              'code': 'ABC123DEF456',
              'remaining': 30000,
              'active': false,
              'invited': 2,
              'earned': 50000,
              'test_earned': 20000,
              'claimed': claimed,
              'can_claim': !claimed,
              'history': [
                {
                  'credits': 50000,
                  'mode': 'live',
                  'created_at': '2026-10-18T10:00:00Z',
                },
              ],
            },
            claim: (code) async {
              applied = code;
              claimed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ABC123DEF456'), findsOneWidget);
      expect(find.textContaining('Locked until'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(find.byType(TextField), 'FRIEND123');
      await tester.ensureVisible(find.text('Apply friend code'));
      await tester.tap(find.text('Apply friend code'));
      await tester.pumpAndSettle();
      expect(applied, 'FRIEND123');
      expect(
        find.text('Your friend’s referral code is saved.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('referral page retries failed loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReferralsScreen(load: () async => throw StateError('private')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry referrals'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
  });
}
