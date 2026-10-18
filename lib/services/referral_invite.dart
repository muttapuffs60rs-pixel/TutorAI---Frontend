import 'package:shared_preferences/shared_preferences.dart';

String referralLink(String code) =>
    Uri.https('arivora.onrender.com', '/', {'ref': code}).toString();
String? referralFromUri(Uri uri) {
  final code = uri.queryParameters['ref']?.trim().toUpperCase();
  return code != null && RegExp(r'^[A-F0-9]{12}$').hasMatch(code) ? code : null;
}

Future<void> rememberReferral(Uri uri) async {
  final code = referralFromUri(uri);
  if (code != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('last_referral_link') == code) return;
      await prefs.setString('pending_referral_code', code);
      await prefs.setString('last_referral_link', code);
    } catch (_) {
      /* Keep sign-in working if browser storage is unavailable. */
    }
  }
}

Future<String?> pendingReferral() async {
  try {
    return (await SharedPreferences.getInstance()).getString(
      'pending_referral_code',
    );
  } catch (_) {
    return null;
  }
}

Future<void> clearReferral() async {
  try {
    await (await SharedPreferences.getInstance()).remove(
      'pending_referral_code',
    );
  } catch (_) {
    /* Nonessential local invitation hint. */
  }
}
