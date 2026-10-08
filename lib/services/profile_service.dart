import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';

/// Daily rollover and privileged counters belong to the API, not the device.
Future<Map<String, dynamic>> fetchDailyProfile() async {
  final token = supabase.auth.currentSession?.accessToken;
  if (token == null) throw StateError('Please sign in again');
  final response = await http
      .get(
        Uri.parse('https://akka-tutor-backend.onrender.com/profile'),
        headers: {'Authorization': 'Bearer $token'},
      )
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw StateError('Could not load your profile');
  }
  return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
}
