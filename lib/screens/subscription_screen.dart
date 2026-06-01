import 'package:flutter/material.dart';
import '../main.dart'; // Ensure this points to your main.dart where supabase is initialized

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  // Function to handle the subscription logic with specific expiry for the daily pass
  Future<void> _updateSubscription(String tierName, int days) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      DateTime expiry;

      // Logic for Same-Day Midnight Expiry for Tier 49
      if (tierName == 'tier_49_daily') {
        final now = DateTime.now();
        // Sets expiry to 23:59:59 (11:59 PM) of the current day
        expiry = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else {
        // Standard 30-day logic for other monthly tiers
        expiry = DateTime.now().add(Duration(days: days));
      }

      final expiryDate = expiry.toIso8601String();

      // Update the user profile with the new tier and expiry date
      await supabase.from('profiles').update({
        'subscription_tier': tierName,
        'subscription_expires_at': expiryDate, 
      }).eq('id', user.id);

      if (mounted) {
        String successMessage = tierName == 'tier_49_daily' 
            ? "Exam Booster active until 11:59 PM tonight!" 
            : "Success! $tierName activated for $days days.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        Navigator.pop(context); // Return to chat screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating subscription: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkPurple = Color(0xFF5A189A);
    const Color lightPurple = Color(0xFF9D4EDD);

    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      appBar: AppBar(
        title: const Text('Upgrade to Preethi Pro', style: TextStyle(color: Colors.white)),
        backgroundColor: darkPurple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.stars, size: 80, color: Colors.yellowAccent),
                const SizedBox(height: 20),
                const Text(
                  'Achieve Your Best Marks!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose the plan that fits your study schedule.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // EXAM BOOSTER - ₹49 (Expires Tonight)
                _buildPlanCard(
                  title: 'Exam Booster',
                  price: '₹49',
                  subtitle: 'Valid until 11:59 PM Tonight',
                  features: ['Unlimited Chats today', 'High-speed responses', 'Perfect for last-minute prep'],
                  color: Colors.orangeAccent.shade700,
                  buttonText: 'Get Today\'s Pass',
                  onTap: () => _updateSubscription('tier_49_daily', 1),
                ),
                const SizedBox(height: 20),

                // STANDARD - ₹199 (30 Days)
                _buildPlanCard(
                  title: 'Standard',
                  price: '₹199',
                  subtitle: 'Monthly subscription',
                  features: ['50 Chats/Day', 'Full Textbook Context', 'Standard Support'],
                  color: darkPurple,
                  buttonText: 'Choose Standard',
                  onTap: () => _updateSubscription('tier_199', 30),
                ),
                const SizedBox(height: 20),

                // SYLLABUS MASTER - ₹499 (30 Days)
                _buildPlanCard(
                  title: 'Syllabus Master',
                  price: '₹499',
                  subtitle: 'Monthly subscription',
                  features: ['150 Chats/Day', 'Priority AI Access', 'Centum-focused Tips'],
                  color: lightPurple,
                  isPro: true,
                  buttonText: 'Go Pro Master',
                  onTap: () => _updateSubscription('tier_499', 30),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title, 
    required String price, 
    required String subtitle,
    required List<String> features, 
    required Color color, 
    required String buttonText,
    required VoidCallback onTap,
    bool isPro = false
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: isPro ? Border.all(color: Colors.yellowAccent, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(color: Colors.yellowAccent, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Divider(color: Colors.white24, height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18), 
              const SizedBox(width: 10), 
              Expanded(child: Text(f, style: const TextStyle(color: Colors.white)))
            ]),
          )),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}