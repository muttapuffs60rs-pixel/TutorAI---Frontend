import 'package:flutter/material.dart';
import 'Support_screen.dart';

enum LegalPolicy { terms, refunds }

class LegalPolicyScreen extends StatelessWidget {
  const LegalPolicyScreen({super.key, required this.policy});

  final LegalPolicy policy;
  static const supportEmail = 'arivora_support@auxiumsoft.com';
  static const version = '2026-10-14';

  static void open(BuildContext context, LegalPolicy policy) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalPolicyScreen(policy: policy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTerms = policy == LegalPolicy.terms;
    final sections = isTerms ? _terms : _refunds;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTerms ? 'Terms and Conditions' : 'Cancellation and Refund Policy',
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Arivora',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Last updated: 14 October 2026'),
                  const SizedBox(height: 24),
                  for (final section in sections) ...[
                    Text(
                      section.$1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(section.$2, style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 24),
                  ],
                  const SelectableText('Contact: $supportEmail'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SupportScreen(paymentRequest: !isTerms),
                      ),
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact support'),
                  ),
                  TextButton(
                    onPressed: () => open(
                      context,
                      isTerms ? LegalPolicy.refunds : LegalPolicy.terms,
                    ),
                    child: Text(
                      isTerms
                          ? 'Read Cancellation and Refund Policy'
                          : 'Read Terms and Conditions',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _terms = <(String, String)>[
  (
    '1. Using Arivora',
    'Arivora is operated by AuxiumSoft. These terms govern your use of Arivora, its AI tutoring, textbook explanations, practice and classroom quizzes. References to we, us or our mean AuxiumSoft. Read these terms and the Cancellation and Refund Policy before creating an account or purchasing access.',
  ),
  (
    '2. Students and accounts',
    'If you are under 18, use Arivora with the permission and supervision of a parent or legal guardian. A parent or guardian must authorise purchases for a minor. Provide accurate account details, protect your password and contact support if you suspect unauthorised access.',
  ),
  (
    '3. Educational use',
    'Arivora is a learning aid. AI explanations and generated quizzes may contain mistakes. Check important answers against your textbook or teacher. We do not guarantee marks, examination results or admission outcomes. Do not use the service to cheat in examinations.',
  ),
  (
    '4. Plans, allowances and delivery',
    'The purchase screen shows the price, duration and included features. Paid plans provide access for 30 days after successful payment verification. Purchases are one-time payments and do not automatically renew. Top-ups expire with your active subscription, or after 10 days without an active subscription. Usage allowances and feature limits apply; access is not unlimited. Access is delivered digitally after payment verification; no physical goods are shipped.',
  ),
  (
    '5. Payments',
    'Payments are processed through Razorpay. Review the final amount and currency before paying. If money is debited but access is not activated, do not pay again; contact support with your payment or order ID. Cancellation and refund requests follow the separate Cancellation and Refund Policy.',
  ),
  (
    '6. Responsible use and content',
    'Do not upload unlawful content, infringe intellectual property, harass others, attempt unauthorised access, disrupt the service or bypass usage limits. Submit only material you have permission to share. Avoid including sensitive personal information in questions or images. Textbooks and third-party materials remain the property of their respective owners.',
  ),
  (
    '7. Availability and account restrictions',
    'Maintenance, network problems and third-party outages may interrupt access. We may restrict accounts used for abuse or violations of these terms. Contact support to question a restriction or report a service problem. These terms do not remove any remedy you are entitled to under applicable law.',
  ),
  (
    '8. Changes and support',
    'Updates to these terms will be shown with a revised date. Purchase-specific terms apply to the purchase made under them; changes do not remove accrued consumer rights. For account, payment or policy questions, contact arivora_support@auxiumsoft.com.',
  ),
];

const _refunds = <(String, String)>[
  (
    '1. Cancelling a purchase or future access',
    'This policy applies to purchases of Arivora access from AuxiumSoft. You can close checkout before completing payment. Closing checkout after a debit does not reverse that payment; contact support if payment status is unclear. Plans are one-time purchases with no automatic renewal, so you can stop future purchases without cancelling a recurring mandate. Uninstalling the app or deleting an account does not itself request a refund.',
  ),
  (
    '2. Refund requests',
    'Refunds are available only for verified duplicate charges and successful payments for which the purchased plan or top-up access was not delivered, except where applicable law requires otherwise. Contact support with your payment details so we can verify the issue. For a duplicate charge, the extra payment is eligible for a refund. For undelivered access, support will confirm the payment and refund eligibility. Once purchased access has been delivered, we do not offer refunds for change of mind, unused access or allowances, early cancellation, or expiry of a plan or top-up.',
  ),
  (
    '3. How to request help',
    'Email arivora_support@auxiumsoft.com with your account email, payment or order ID, payment date, amount and reason. Attach a receipt or screenshot if available. Never send your password, OTP, card PIN or full card details. Sending a request does not automatically cancel access or confirm a refund.',
  ),
  (
    '4. Refund processing',
    'Support will communicate the outcome and, for an approved refund, its initiation status. Approved refunds are returned through the payment provider to the original payment method. Bank and payment-network processing times vary; contact support for the refund reference and status if the credit is delayed. Any adjustment to refunded plan access or allowances will be explained when the refund is confirmed.',
  ),
  (
    '5. Your rights',
    'This policy does not exclude refunds or other remedies required by applicable law. Contact support if purchased access is unavailable or materially different from what was described at checkout.',
  ),
];

class LegalPolicyLinks extends StatelessWidget {
  const LegalPolicyLinks({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      TextButton(
        onPressed: () => LegalPolicyScreen.open(context, LegalPolicy.terms),
        child: const Text('Terms and Conditions'),
      ),
      TextButton(
        onPressed: () => LegalPolicyScreen.open(context, LegalPolicy.refunds),
        child: const Text('Cancellation and Refund Policy'),
      ),
    ],
  );
}
