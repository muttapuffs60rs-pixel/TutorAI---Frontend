import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // Ensure access to your supabase instance

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // --- Support Actions ---

  void _launchWhatsApp(BuildContext context) async {
    const String phoneNumber = "91XXXXXXXXXX"; // Replace with your actual number
    const String message = "Vanakkam Akka! I need help with my subscription.";
    final Uri url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showError(context, "Could not open WhatsApp. Please ensure it is installed.");
    }
  }

  void _launchEmail(BuildContext context) async {
    final String userId = supabase.auth.currentUser?.id ?? "Not Logged In";
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@yourdomain.com', // Replace with your support email
      query: 'subject=Support Request: Akka AI Tutor&body=User ID: $userId\n\nIssue Description:',
    );

    if (!await launchUrl(emailLaunchUri)) {
      _showError(context, "Could not open your email app.");
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    final String userId = supabase.auth.currentUser?.id ?? "N/A";
    const Color brandPurple = Color(0xFF7B2CBF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A189A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "How can we help you today?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandPurple),
            ),
            const SizedBox(height: 10),
            const Text(
              "Our support team is available from 9 AM to 9 PM IST.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // WhatsApp Card
            _buildSupportCard(
              title: "WhatsApp Support",
              subtitle: "Instant help for payment issues",
              icon: Icons.chat_bubble_outline,
              color: Colors.green.shade600,
              onTap: () => _launchWhatsApp(context),
            ),

            const SizedBox(height: 15),

            // Email Card
            _buildSupportCard(
              title: "Email Support",
              subtitle: "For feedback and technical bugs",
              icon: Icons.alternate_email,
              color: Colors.blue.shade700,
              onTap: () => _launchEmail(context),
            ),

            const Spacer(),

            // Technical Info Section (Very helpful for you!)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text("Technical Information", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text("ID: $userId", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Copied!")));
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}