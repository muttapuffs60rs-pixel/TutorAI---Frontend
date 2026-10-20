import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tutor_preethi/services/signup_error_message.dart';

void main() {
  const failure =
      '{"code":"unexpected_failure","message":"Database error saving new user"}';
  test('confirmed duplicate shows the requested message', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.body, '{"phone":"9000000000"}');
      expect(request.url.path, '/auth/signup-phone-status');
      return http.Response('{"registered":true}', 200);
    });
    expect(await signupErrorMessage(failure, '9000000000', client: client),
        duplicateMobileMessage);
  });
  test('unrelated auth errors are preserved without querying phones', () async {
    final client = MockClient((_) async => throw StateError('must not call'));
    expect(await signupErrorMessage('Invalid email', '9000000000', client: client),
        'Invalid email');
  });
  test('unused number and failed diagnostics never claim a duplicate', () async {
    for (final response in [
      http.Response('{"registered":false}', 200),
      http.Response('{"registered":true}', 503),
      http.Response('invalid json', 200),
    ]) {
      expect(
          await signupErrorMessage(failure, '9000000000',
              client: MockClient((_) async => response)),
          signupRetryMessage);
    }
    expect(
        await signupErrorMessage(failure, '9000000000',
            client: MockClient((_) async => throw Exception('offline'))),
        signupRetryMessage);
  });
}
