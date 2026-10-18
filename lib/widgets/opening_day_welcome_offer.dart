import 'package:flutter/material.dart';

class OpeningDayWelcomeOffer extends StatelessWidget {
  final DateTime? now;
  final DateTime? accountCreatedAt;
  const OpeningDayWelcomeOffer({super.key, this.now, this.accountCreatedAt});

  static final startsAt = DateTime.parse('2026-10-20T00:00:00+05:30');
  static final endsAt = DateTime.parse('2026-10-21T00:00:00+05:30');

  @override
  Widget build(BuildContext context) {
    final created = accountCreatedAt;
    final eligible =
        created != null &&
        !created.isBefore(startsAt) &&
        created.isBefore(endsAt);
    if (!eligible && !(now ?? DateTime.now()).isBefore(endsAt)) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eligible
                  ? 'Your opening-day welcome grant'
                  : 'Opening-day offer · 20 October 2026',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              eligible
                  ? 'Your account qualifies for 50,000 welcome credits: 30,000 standard + 20,000 bonus. Check your remaining balance in the usage meter.'
                  : 'New accounts created on opening day receive 50,000 welcome credits: 30,000 standard + 20,000 bonus.',
            ),
            const SizedBox(height: 8),
            const Text(
              'One grant per account. No purchase needed. Eligibility uses account creation from midnight on 20 October to midnight on 21 October IST; you can first use the credits later.',
            ),
          ],
        ),
      ),
    );
  }
}
