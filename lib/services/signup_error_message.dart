import 'dart:convert';
import 'package:http/http.dart' as http;

const duplicateMobileMessage =
    'This mobile number is already registered. Please log in or use Forgot Password.';
const signupRetryMessage =
    'We could not create your account. Please try again or contact support.';

/// Supabase masks trigger constraint errors. Check only that failure case,
/// and never mislabel an unavailable diagnostic as a duplicate mobile number.
Future<String> signupErrorMessage(
  String message,
  String phone, {
  http.Client? client,
}) async {
  if (!message.toLowerCase().contains('database error saving new user')) {
    return message;
  }
  final connection = client ?? http.Client();
  try {
    final response = await connection
        .post(
          Uri.parse(
            'https://akka-tutor-backend.onrender.com/auth/signup-phone-status',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 200 &&
        jsonDecode(response.body)['registered'] == true) {
      return duplicateMobileMessage;
    }
  } catch (_) {
    // Keep a useful fallback if the diagnostic service is unavailable.
  } finally {
    if (client == null) connection.close();
  }
  return signupRetryMessage;
}
