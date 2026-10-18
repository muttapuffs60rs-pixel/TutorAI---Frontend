import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutor_preethi/services/referral_invite.dart';

void main() {
  test(
    'invitation link safely carries code and persists through sign-up',
    () async {
      SharedPreferences.setMockInitialValues({});
      final link = referralLink('ABCDEF123456');
      expect(link, 'https://arivora.onrender.com/?ref=ABCDEF123456');
      await rememberReferral(Uri.parse(link));
      expect(await pendingReferral(), 'ABCDEF123456');
      await rememberReferral(
        Uri.parse('https://arivora.onrender.com/?ref=bad'),
      );
      expect(await pendingReferral(), 'ABCDEF123456');
      await clearReferral();
      expect(await pendingReferral(), isNull);
    },
  );
}
