import 'package:flutter/material.dart';
import '../services/referral_invite.dart';
import '../screens/referrals_screen.dart';

class ReferralInviteBanner extends StatefulWidget {
  const ReferralInviteBanner({super.key});
  @override
  State<ReferralInviteBanner> createState() => _ReferralInviteBannerState();
}

class _ReferralInviteBannerState extends State<ReferralInviteBanner> {
  String? _code;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code = await pendingReferral();
    if (mounted) setState(() => _code = code);
  }

  @override
  Widget build(BuildContext context) => _code == null
      ? const SizedBox.shrink()
      : Card(
          child: ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('You have a friend’s invitation'),
            subtitle: const Text(
              'Your referral code is ready. Confirm it before your first payment.',
            ),
            trailing: IconButton(
              tooltip: 'Dismiss invitation',
              icon: const Icon(Icons.close),
              onPressed: () async {
                await clearReferral();
                await _load();
              },
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReferralsScreen()),
              );
              await _load();
            },
          ),
        );
}
