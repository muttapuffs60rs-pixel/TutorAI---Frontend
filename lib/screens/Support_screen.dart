import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key, this.paymentRequest = false});
  final bool paymentRequest;
  static const email = 'arivora_support@auxiumsoft.com';
  String get requestTemplate => paymentRequest
      ? 'Subject: Arivora payment or refund request\n\nAccount email:\nPayment / order ID:\nPayment date and amount:\nReason for request:\n'
      : 'Subject: Arivora support request\n\nAccount email:\nWhat happened:\nWhat I expected:\nSteps to reproduce:\n';

  Future<void> _copy(BuildContext context, String text, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Copy was unavailable. Select and copy the text below manually.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contact support')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.support_agent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'How can we help?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Send an email to our support team. Copy the address below, then open Gmail, Outlook or your preferred email app and paste it into the To field.',
                ),
                const SizedBox(height: 20),
                const SelectableText(
                  email,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _copy(
                    context,
                    email,
                    'Support email copied. Paste it into your email app.',
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy email address'),
                ),
                const SizedBox(height: 28),
                Text(
                  paymentRequest
                      ? 'Payment or refund request'
                      : 'Tell us what happened',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Copy this template into your message, fill in the details and attach a screenshot if helpful.',
                ),
                const SizedBox(height: 12),
                SelectableText(requestTemplate),
                OutlinedButton.icon(
                  onPressed: () => _copy(
                    context,
                    requestTemplate,
                    'Request template copied. Paste it into your email and fill in the details.',
                  ),
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy request template'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Never include your password, OTP, card PIN or full card details.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your request is sent only when you send the email from your email app.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
