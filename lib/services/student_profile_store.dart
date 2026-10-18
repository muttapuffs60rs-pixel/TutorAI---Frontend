import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'profile_service.dart';

int? currentAvailableCredits(Map<String, dynamic> usage) {
  final wallet = usage['learning_credits'];
  if (wallet is Map) return (wallet['remaining'] as num?)?.toInt();
  final target = usage['token_target'] ?? usage['monthly_token_target'];
  final used = usage['monthly_credits_used'] ?? usage['monthly_tokens_used'];
  if (target is! num ||
      used is! num ||
      (usage['unmetered_requests'] as num? ?? 0) > 0) {
    return null;
  }
  return ((target - used).clamp(0, target) +
          (usage['topup_remaining'] as num? ?? 0) +
          (usage['referral_remaining'] as num? ?? 0))
      .toInt();
}

DateTime? validBirthDate(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final date = DateTime.tryParse(value);
  if (date == null ||
      date.year < 1900 ||
      date.isAfter(DateTime.now()) ||
      date.toIso8601String().substring(0, 10) != value) {
    return null;
  }
  return date;
}

abstract class StudentProfileStore {
  Future<Map<String, dynamic>> account();
  Future<void> saveDetails(String name, String? dateOfBirth);
  Future<void> saveBoard(String board);
  Future<List<Map<String, dynamic>>> learning(int offset);
  Future<Map<String, dynamic>> credits(int offset);
}

class SupabaseStudentProfileStore implements StudentProfileStore {
  @override
  Future<Map<String, dynamic>> account() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw StateError('Please sign in again.');
    final profile = await fetchDailyProfile();
    return {
      ...profile,
      'name':
          (user.userMetadata?['full_name'] ??
                  user.userMetadata?['username'] ??
                  'Student')
              .toString(),
      'email': user.email ?? '',
      'joined_at': user.createdAt,
      'board': user.userMetadata?['education_board'],
      'date_of_birth': user.userMetadata?['date_of_birth'],
    };
  }

  @override
  Future<void> saveDetails(String name, String? dateOfBirth) async {
    if (name.trim().isEmpty ||
        name.length > 60 ||
        (dateOfBirth != null && validBirthDate(dateOfBirth) == null)) {
      throw ArgumentError('Invalid profile details');
    }
    if (supabase.auth.currentUser == null) {
      throw StateError('Please sign in again.');
    }
    await supabase.auth
        .updateUser(
          UserAttributes(
            data: {'full_name': name, 'date_of_birth': dateOfBirth},
          ),
        )
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<void> saveBoard(String board) async {
    if (!['tn', 'cbse'].contains(board)) {
      throw ArgumentError('Unsupported board');
    }
    await supabase.auth.updateUser(
      UserAttributes(data: {'education_board': board}),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> learning(int offset) async {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Please sign in again.');
    final rows = await supabase
        .from('chat_sessions')
        .select('id,title,board,grade_level,subject,created_at')
        .eq('user_id', id)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 19)
        .timeout(const Duration(seconds: 30));
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> credits(int offset) async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Please sign in again.');
    const backend = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://akka-tutor-backend.onrender.com',
    );
    final response = await http
        .get(
          Uri.parse('$backend/profile/activity?offset=$offset'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw StateError('Could not load your credit history.');
    }
    final result = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if ((result['items'] as List).any(
      (item) => item['credit_pending'] == null,
    )) {
      final usageResponse = await http
          .get(
            Uri.parse('$backend/usage'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));
      if (usageResponse.statusCode != 200) {
        throw StateError('Could not load your current balance.');
      }
      result['current_credit_balance'] = currentAvailableCredits(
        Map<String, dynamic>.from(jsonDecode(usageResponse.body) as Map),
      );
    }
    return result;
  }
}
