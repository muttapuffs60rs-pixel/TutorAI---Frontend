import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';

class AnswerLibraryService {
  static const _base = 'https://akka-tutor-backend.onrender.com/answer-library';

  Map<String, String> get _headers {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Please sign in again');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    if (response.statusCode == 403)
      throw StateError('Administrator access required');
    if (response.statusCode == 409)
      throw StateError(
        'This answer changed. Go back and refresh before saving.',
      );
    throw StateError('Could not complete the request. Please try again.');
  }

  Future<List<Map<String, dynamic>>> list(String status, int offset) async {
    final response = await http
        .get(
          Uri.parse('$_base?status=$status&offset=$offset'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));
    return List<Map<String, dynamic>>.from(
      _decode(response)['answers'] as List,
    );
  }

  Future<void> review(String id, Map<String, dynamic> review) async {
    _decode(
      await http
          .patch(
            Uri.parse('$_base/$id'),
            headers: _headers,
            body: jsonEncode(review),
          )
          .timeout(const Duration(seconds: 30)),
    );
  }

  Future<void> report(String id) async {
    _decode(
      await http
          .post(Uri.parse('$_base/$id/report'), headers: _headers)
          .timeout(const Duration(seconds: 30)),
    );
  }
}
