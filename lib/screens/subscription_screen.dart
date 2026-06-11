import 'package:flutter/material.dart';
import '../main.dart'; // Ensure this points to your main.dart where supabase is initialized
import '../theme/tailwind_theme.dart';

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

      // Fetch current profile to handle previous_tier logic
      final data = await supabase.from('profiles').select('subscription_tier, previous_tier').eq('id', user.id).single();
      final String currentTier = data['subscription_tier'] ?? 'free';
      String? previousTier = data['previous_tier'];

      // Save their existing monthly plan if they buy the daily booster
      if (tierName == 'tier_49_daily' && currentTier != 'tier_49_daily' && currentTier != 'free') {
        previousTier = currentTier;
      }
      
      // If they buy a new standard/pro plan, clear previous_tier
      if (tierName != 'tier_49_daily') {
        previousTier = null;
      }

      // Update the user profile with the new tier, expiry date, and previous_tier
      await supabase.from('profiles').update({
        'subscription_tier': tierName,
        'subscription_expires_at': expiryDate, 
        'previous_tier': previousTier,
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
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        title: const Text('Upgrade to Preethi Pro', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)),
        backgroundColor: Tailwind.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Tailwind.slate800),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Tailwind.amber500, Tailwind.orange500]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Tailwind.orange500.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, size: 64, color: Tailwind.white),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Achieve Your Best Marks!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Tailwind.slate800, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose the plan that fits your study schedule.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Tailwind.slate500, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // EXAM BOOSTER - ₹49 (Expires Tonight)
                _buildPlanCard(
                  title: 'Exam Booster',
                  price: '₹49',
                  subtitle: 'Valid until 11:59 PM Tonight',
                  features: ['Unlimited Chats today', 'High-speed responses', 'Perfect for last-minute prep'],
                  isBooster: true,
                  buttonText: 'Get Today\'s Pass',
                  onTap: () => _updateSubscription('tier_49_daily', 1),
                ),
                const SizedBox(height: 24),

                // STANDARD - ₹199 (30 Days)
                _buildPlanCard(
                  title: 'Standard',
                  price: '₹199',
                  subtitle: 'Monthly subscription',
                  features: ['50 Chats/Day', 'Full Textbook Context', 'Standard Support'],
                  buttonText: 'Choose Standard',
                  onTap: () => _updateSubscription('tier_199', 30),
                ),
                const SizedBox(height: 24),

                // SYLLABUS MASTER - ₹499 (30 Days)
                _buildPlanCard(
                  title: 'Syllabus Master',
                  price: '₹499',
                  subtitle: 'Monthly subscription',
                  features: ['150 Chats/Day', 'Priority AI Access', 'Centum-focused Tips'],
                  isPro: true,
                  buttonText: 'Go Pro Master',
                  onTap: () => _updateSubscription('tier_499', 30),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Tailwind.indigo600)),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title, 
    required String price, 
    required String subtitle,
    required List<String> features, 
    required String buttonText,
    required VoidCallback onTap,
    bool isPro = false,
    bool isBooster = false,
  }) {
    final bool isDarkCard = isPro;
    final Color textColor = isDarkCard ? Tailwind.white : Tailwind.slate800;
    final Color subtitleColor = isDarkCard ? Tailwind.slate200 : Tailwind.slate500;
    final Color iconColor = isDarkCard ? Tailwind.emerald400 : (isBooster ? Tailwind.amber500 : Tailwind.emerald500);
    final Color dividerColor = isDarkCard ? Tailwind.white.withOpacity(0.2) : Tailwind.slate200;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDarkCard ? null : Tailwind.white,
            gradient: isDarkCard ? const LinearGradient(
              colors: [Tailwind.indigo600, Tailwind.purple600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            borderRadius: Tailwind.rounded3Xl,
            boxShadow: isDarkCard ? Tailwind.shadowLg : Tailwind.shadowMd,
            border: isDarkCard ? null : Border.all(color: isBooster ? Tailwind.amber500 : Tailwind.slate200, width: isBooster ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDarkCard ? Tailwind.white : (isBooster ? Tailwind.amber600 : Tailwind.indigo600), fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: TextStyle(color: textColor, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: dividerColor, height: 1),
              const SizedBox(height: 24),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Icon(Icons.check_circle, color: iconColor, size: 22), 
                  const SizedBox(width: 12), 
                  Expanded(child: Text(f, style: TextStyle(color: isDarkCard ? Tailwind.slate100 : Tailwind.slate700, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)))
                ]),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: isDarkCard ? Tailwind.white : (isBooster ? Tailwind.amber500 : Tailwind.indigo600), 
                    foregroundColor: isDarkCard ? Tailwind.indigo600 : Tailwind.white,
                    elevation: isDarkCard ? 2 : 0,
                    shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
        if (isPro || isBooster)
          Positioned(
            top: -14,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isPro ? Tailwind.amber500 : Tailwind.orange500,
                borderRadius: Tailwind.roundedFull,
                boxShadow: Tailwind.shadowSm,
              ),
              child: Text(
                isPro ? 'MOST POPULAR' : 'LIMITED OFFER',
                style: TextStyle(
                  color: isPro ? Tailwind.slate900 : Tailwind.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}