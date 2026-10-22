import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutor_preethi/screens/login_screen.dart';
import 'package:tutor_preethi/screens/forgot_password_screen.dart';

void main() {
  final requests = <http.Request>[];
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://negative-audit.invalid',
      anonKey: 'synthetic',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{"msg":"Synthetic rejection"}',
          400,
          headers: {'content-type': 'application/json'},
        );
      }),
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  });
  setUp(requests.clear);
  Future<void> signup(WidgetTester tester, String phone) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
    final fields = find.byType(TextField);
    for (final pair in <int, String>{
      0: 'Audit',
      1: phone,
      2: 'audit@example.invalid',
      3: 'SyntheticPass123!',
      4: 'SyntheticPass123!',
    }.entries) {
      await tester.enterText(fields.at(pair.key), pair.value);
    }
    final button = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.ensureVisible(button);
    await tester.runAsync(() async {
      await tester.tap(button);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('empty login is rejected before network', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    expect(find.text('Please enter your email and password'), findsOneWidget);
  });
  testWidgets('alphabetic mobile number is rejected before signup', (
    tester,
  ) async {
    await signup(tester, 'abcdefghij');
    expect(
      requests,
      isEmpty,
      reason: 'A ten-letter value must not reach signup as a mobile number',
    );
  });
  testWidgets('login preserves password whitespace', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.enterText(
      find.byType(TextField).at(0),
      'audit@example.invalid',
    );
    await tester.enterText(find.byType(TextField).at(1), ' SyntheticPass123! ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();
    expect(jsonDecode(requests.single.body)['password'], ' SyntheticPass123! ');
  });
  testWidgets(
    'mobile login directs user to registered email without a request',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextField).at(0), '9000000000');
      await tester.enterText(find.byType(TextField).at(1), 'SyntheticPass123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      expect(
        find.text('Please use the email address you registered with.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'recovery rejects mobile and never sends SMS or creates account',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
      await tester.enterText(find.byType(TextField), '9000000000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      expect(
        find.text('Please enter your registered email address'),
        findsOneWidget,
      );
    },
  );
}
