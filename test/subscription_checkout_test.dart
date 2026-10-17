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

  for (final scenario in [
    'verified',
    'cancelled',
    'activation failed',
    'order failed',
    'live key',
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
          expect(jsonDecode(request.body)['tier_id'], 'tier_199');
          if (scenario == 'order failed') {
            return http.Response(
              '{"detail":"Payment provider unavailable"}',
              502,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'order_synthetic',
              'key_id': scenario == 'live key'
                  ? 'rzp_live_synthetic'
                  : 'rzp_test_synthetic',
              'amount': 24900,
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
                      profileLoader: () async => {
                        'subscription_tier': 'tier_199',
                        'subscription_expires_at': '2099-01-01T00:00:00Z',
                      },
                      httpClient: client,
                      openCheckout: (options) async {
                        checkoutCalls++;
                        expect(options['key'], 'rzp_test_synthetic');
                        expect(options['amount'], 24900);
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
      expect(find.text('Monthly tracking target'), findsOneWidget);
      expect(find.text('LIMITED OFFER'), findsNothing);
      await tester.scrollUntilVisible(find.byType(CheckboxListTile), 350);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Choose Standard'), 350);
      await tester.tap(find.text('Choose Standard'));
      await tester.pumpAndSettle();
      expect(
        verificationCalls,
        scenario == 'verified' || scenario == 'activation failed' ? 1 : 0,
      );
      expect(
        checkoutCalls,
        scenario == 'order failed' || scenario == 'live key' ? 0 : 1,
      );
      if (scenario == 'verified') {
        expect(find.text('Open plans'), findsOneWidget);
        expect(find.text('Standard activated for 30 days.'), findsOneWidget);
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
