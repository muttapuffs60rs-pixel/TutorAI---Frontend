import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutor_preethi/screens/subscription_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://payment-tests.invalid',
      anonKey: 'synthetic-test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'access_token': 'synthetic-test-session',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'synthetic-test-refresh',
            'user': {
              'id': 'test-student',
              'aud': 'authenticated',
              'email': 'student@example.invalid',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'student@example.invalid',
      password: 'synthetic-only',
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  for (final tier in [
    'free',
    'admin',
    'tier_49_daily',
    'tier_199',
    'tier_499',
    'tier_999',
  ]) {
    for (final active in [true, false]) {
      testWidgets('Top-up eligibility $tier active=$active', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionScreen(
              profileLoader: () async => {
                'subscription_tier': tier,
                'subscription_expires_at': active
                    ? '2099-01-01T00:00:00Z'
                    : '2020-01-01T00:00:00Z',
              },
              paymentStatusLoader: () async => {
                'mode': 'test',
                'checkout_enabled': true,
                'topups_enabled': true,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final eligible =
            active && ['tier_199', 'tier_499', 'tier_999'].contains(tier);
        expect(find.text('COMING SOON'), findsNothing);
        expect(find.text('Top-up coming soon'), findsNothing);
        expect(
          find.text(
            eligible ? 'Buy top-up ₹49' : 'Active subscription required',
          ),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(find.byType(CheckboxListTile), 350);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        final button = find.widgetWithText(
          ElevatedButton,
          eligible ? 'Buy top-up ₹49' : 'Active subscription required',
        );
        expect(
          tester.widget<ElevatedButton>(button).onPressed != null,
          eligible,
        );
      });
    }
  }

  for (final scenario in [
    'verified',
    'topup verified',
    'cancelled',
    'activation failed',
    'order failed',
    'live key',
    'live verified',
    'live disabled',
    'status unavailable',
  ]) {
    testWidgets('Checkout handles $scenario without an actual payment', (
      tester,
    ) async {
      var verificationCalls = 0;
      var checkoutCalls = 0;
      final client = MockClient((request) async {
        expect(
          request.headers['authorization'],
          'Bearer synthetic-test-session',
        );
        if (request.url.path.endsWith('create-order')) {
          expect(
            jsonDecode(request.body)['tier_id'],
            scenario == 'topup verified' ? 'topup_49' : 'tier_199',
          );
          if (scenario == 'order failed') {
            return http.Response(
              '{"detail":"Payment provider unavailable"}',
              502,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'order_synthetic',
              'key_id': (scenario == 'live key' || scenario == 'live verified')
                  ? 'rzp_live_synthetic'
                  : 'rzp_test_synthetic',
              'amount': scenario == 'topup verified' ? 4900 : 24900,
              'currency': 'INR',
            }),
            200,
          );
        }
        verificationCalls++;
        expect(
          jsonDecode(request.body)['razorpay_order_id'],
          'order_synthetic',
        );
        return http.Response(
          scenario == 'activation failed'
              ? '{"detail":"Verification unavailable"}'
              : '{"status":"success"}',
          scenario == 'activation failed' ? 503 : 200,
        );
      });
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SubscriptionScreen(
                      paymentStatusLoader: () async => {
                        'mode':
                            scenario.startsWith('live ') &&
                                scenario != 'live key'
                            ? 'live'
                            : 'test',
                        'checkout_enabled': scenario != 'status unavailable',
                        'topups_enabled': true,
                        'live_charging_enabled': scenario == 'live verified',
                      },
                      profileLoader: () async => {
                        'subscription_tier': 'tier_199',
                        'subscription_expires_at': '2099-01-01T00:00:00Z',
                      },
                      httpClient: client,
                      openCheckout: (options) async {
                        checkoutCalls++;
                        expect(
                          options['key'],
                          scenario == 'live verified'
                              ? 'rzp_live_synthetic'
                              : 'rzp_test_synthetic',
                        );
                        expect(
                          options['amount'],
                          scenario == 'topup verified' ? 4900 : 24900,
                        );
                        expect(options['currency'], 'INR');
                        if (scenario == 'cancelled') {
                          throw Exception('Checkout cancelled.');
                        }
                        return {
                          'razorpay_payment_id': 'pay_synthetic',
                          'razorpay_order_id': 'order_synthetic',
                          'razorpay_signature': 'synthetic-signature',
                        };
                      },
                    ),
                  ),
                ),
                child: const Text('Open plans'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open plans'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your current plan: Standard'),
        findsOneWidget,
      );
      expect(find.text('Compare at a glance'), findsOneWidget);
      expect(find.text('Chat replies / day'), findsNothing);
      expect(find.textContaining('chat replies per day'), findsNothing);
      expect(find.text('Monthly tracking target'), findsOneWidget);
      expect(find.text('LIMITED OFFER'), findsNothing);
      await tester.scrollUntilVisible(find.byType(CheckboxListTile), 350);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text(
          scenario == 'topup verified' ? 'Buy top-up ₹49' : 'Choose Standard',
        ),
        350,
      );
      await tester.tap(
        find.text(
          scenario == 'topup verified' ? 'Buy top-up ₹49' : 'Choose Standard',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        verificationCalls,
        scenario == 'verified' ||
                scenario == 'topup verified' ||
                scenario == 'live verified' ||
                scenario == 'activation failed'
            ? 1
            : 0,
      );
      expect(
        checkoutCalls,
        scenario == 'order failed' ||
                scenario == 'live key' ||
                scenario == 'live disabled' ||
                scenario == 'status unavailable'
            ? 0
            : 1,
      );
      if (scenario == 'verified' ||
          scenario == 'topup verified' ||
          scenario == 'live verified') {
        expect(find.text('Open plans'), findsOneWidget);
        expect(
          find.text(
            scenario == 'topup verified'
                ? 'Your 300,000 top-up credits have been added. They expire with your active subscription.'
                : 'Standard activated for 30 days.',
          ),
          findsOneWidget,
        );
      } else {
        expect(find.byType(SubscriptionScreen), findsOneWidget);
        expect(find.textContaining('activated for 30 days.'), findsNothing);
        if (scenario == 'activation failed') {
          expect(find.textContaining('Do not pay again.'), findsOneWidget);
        }
      }
    });
  }
}
