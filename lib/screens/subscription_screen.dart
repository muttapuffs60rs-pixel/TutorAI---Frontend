import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/payment_checkout.dart';
import 'legal_policy_screen.dart';
import '../main.dart'; // Ensure this points to your main.dart where supabase is initialized
import '../theme/tailwind_theme.dart';
import '../services/profile_service.dart';
import '../widgets/opening_day_welcome_offer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.httpClient,
    this.openCheckout,
    this.profileLoader = fetchDailyProfile,
    this.paymentStatusLoader,
  });
  final Future<Map<String, dynamic>> Function() profileLoader;
  final Future<Map<String, dynamic>> Function()? paymentStatusLoader;

  final http.Client? httpClient;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
  openCheckout;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  bool _acceptedPolicies = false;
  String? _currentTier;
  String? _currentExpiry;
  bool _loadingProfile = true;
  Map<String, dynamic>? _paymentStatus;
  bool get _checkoutEnabled =>
      _paymentStatus?['checkout_enabled'] == true &&
      (_paymentStatus?['mode'] == 'test' ||
          (_paymentStatus?['mode'] == 'live' &&
              _paymentStatus?['live_charging_enabled'] == true));

  Future<void> _loadPaymentStatus() async {
    try {
      final status = widget.paymentStatusLoader != null
          ? await widget.paymentStatusLoader!()
          : await (() async {
              final response = await http
                  .get(Uri.parse('$_backend/payments/status'))
                  .timeout(const Duration(seconds: 15));
              if (response.statusCode != 200)
                throw Exception('Payment status unavailable');
              return jsonDecode(response.body) as Map<String, dynamic>;
            })();
      if (mounted) setState(() => _paymentStatus = status);
    } catch (_) {
      if (mounted) setState(() => _paymentStatus = {'checkout_enabled': false});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPaymentStatus();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.profileLoader();
      final expiry = DateTime.tryParse(
        profile['subscription_expires_at']?.toString() ?? '',
      );
      if (mounted) {
        setState(() {
          _currentTier = expiry != null && !expiry.isAfter(DateTime.now())
              ? 'free'
              : profile['subscription_tier'] as String? ?? 'free';
          _currentExpiry = expiry == null
              ? null
              : '${expiry.day}/${expiry.month}/${expiry.year}';
        });
      }
    } catch (_) {
      /* Keep purchase choices available if profile lookup fails. */
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

  PaymentCheckout? _checkout;
  static const _backend = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://akka-tutor-backend.onrender.com',
  );

  @override
  void dispose() {
    _checkout?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Please sign in to make a purchase.');
    final post = widget.httpClient?.post ?? http.post;
    final response = await post(
      Uri.parse('$_backend/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 45));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Payment service is unavailable.');
    }
    return data;
  }

  Future<void> _updateSubscription(String tierName) async {
    if (_isLoading || !_checkoutEnabled) return;
    if (!_acceptedPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the purchase policies first.'),
        ),
      );
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to make a purchase.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    const names = {
      'topup_49': 'Learning Top-up',
      'tier_199': 'Standard',
      'tier_499': 'Syllabus Master',
      'tier_999': 'Premium',
    };
    String? paymentId;
    try {
      final order = await _post('create-order', {'tier_id': tierName});
      if (!mounted) return;
      if (order['key_id'] is! String ||
          !(order['key_id'] as String).startsWith(
            _paymentStatus?['mode'] == 'live' ? 'rzp_live_' : 'rzp_test_',
          ) ||
          order['id'] is! String ||
          order['amount'] is! num ||
          order['currency'] != 'INR') {
        throw Exception(
          'Payment configuration is incomplete. Please contact support.',
        );
      }
      final payment =
          await (widget.openCheckout ??
              (_checkout ??= PaymentCheckout()).open)({
            'key': order['key_id'],
            'amount': order['amount'],
            'currency': order['currency'],
            'order_id': order['id'],
            'name': 'Arivora',
            'description': names[tierName],
            'prefill': {'contact': user.phone ?? '', 'email': user.email ?? ''},
          });
      paymentId = payment['razorpay_payment_id'] as String?;
      final verification = await _post('verify-payment', payment);
      if (verification['status'] != 'success') {
        throw Exception('Payment activation has not been confirmed.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tierName == 'topup_49'
                ? 'Your top-up has been added. It expires with your active subscription, or in 10 days without one.'
                : '${names[tierName]} activated for 30 days.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentId == null
                  ? 'Unable to complete checkout: $error'
                  : 'Payment received, but activation could not be confirmed. Do not pay again. Contact arivora_support@auxiumsoft.com with payment ID $paymentId.',
            ),
            duration: const Duration(seconds: 10),
          ),
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
        title: const Text(
          'Compare study plans',
          style: TextStyle(
            color: Tailwind.slate800,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                      gradient: const LinearGradient(
                        colors: [Tailwind.amber500, Tailwind.orange500],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Tailwind.orange500.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      size: 64,
                      color: Tailwind.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Find your study plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Tailwind.slate800,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose the plan that fits your study schedule.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Tailwind.slate500, fontSize: 16),
                ),
                const SizedBox(height: 32),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _loadingProfile
                          ? 'Loading your current plan…'
                          : _currentTier == null
                          ? 'Your current plan could not be loaded. Check your plan in the menu before purchasing.'
                          : 'Your current plan: ${const {'tier_199': 'Standard', 'tier_499': 'Syllabus Master', 'tier_999': 'Premium', 'free': 'Free', 'admin': 'Admin'}[_currentTier] ?? 'Learning'}${_currentTier != 'free' && _currentExpiry != null ? ' · Valid until $_currentExpiry' : ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Compare at a glance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Tailwind.slate200),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    for (final row in const [
                      ['Plan', 'Standard', 'Syllabus Master', 'Premium'],
                      ['Price / 30 days', '₹249', '₹499', '₹999'],
                      [
                        'Monthly tracking target',
                        '12.5 lakh credits',
                        '30 lakh credits',
                        '80 lakh credits',
                      ],
                      ['Host live quizzes / day', '3', '5', '5'],
                      ['Join live quizzes / day', '10', '15', '15'],
                    ])
                      TableRow(
                        children: row
                            .map(
                              (cell) => Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  cell,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'All plans include textbook-based tutoring. Solo practice: up to 5 generated quizzes per day on every plan.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Monthly study targets track AI processing, including your question, textbook context and the reply. They are not a guaranteed number of answers and are currently tracking targets rather than hard monthly caps. Chat access follows your study credits and plan validity, rather than a daily reply count.',
                ),
                const SizedBox(height: 24),

                const Text(
                  'New accounts receive 30,000 welcome credits once. Free accounts also have a separate daily allowance, shown with remaining welcome credits in the usage meter.',
                ),
                const SizedBox(height: 12),
                const OpeningDayWelcomeOffer(),
                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _paymentStatus == null
                          ? 'Checking payment availability…'
                          : !_checkoutEnabled
                          ? 'Payments are currently unavailable. Please try again later or contact arivora_support@auxiumsoft.com.'
                          : _paymentStatus?['mode'] == 'live'
                          ? 'Secure payment through Razorpay. This is a real payment. Review the plan and amount before paying.'
                          : 'Razorpay Test Mode: no real money is charged. A successful test can update your tester account plan. Use only Razorpay test payment details.',
                    ),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _acceptedPolicies,
                  onChanged: _isLoading
                      ? null
                      : (value) =>
                            setState(() => _acceptedPolicies = value ?? false),
                  title: const Text(
                    'I agree to the Terms and Conditions and Cancellation and Refund Policy. If I am under 18, my parent or guardian has authorised this purchase.',
                  ),
                ),
                const LegalPolicyLinks(),
                const Text(
                  'One-time payments. Plans do not automatically renew. Buying a plan starts a new 30-day period and replaces your current plan; unused days do not stack. Pay using the methods available in Razorpay Checkout, including UPI where enabled.',
                ),
                const SizedBox(height: 24),

                // One-time top-up; does not replace the student's subscription.
                _buildPlanCard(
                  title: 'Learning Top-up',
                  price: '₹49',
                  subtitle:
                      'Valid until your active subscription ends, or 10 days without a subscription',
                  features: [
                    'Extra allowance for your study sessions',
                    'Use after existing allowances',
                    'Does not change your subscription',
                  ],
                  isBooster: true,
                  buttonText: 'Top-up coming soon',
                  onTap: () {},
                  isAvailable: false,
                ),
                const SizedBox(height: 24),

                // STANDARD - ₹249 (legacy storage ID: tier_199)
                _buildPlanCard(
                  title: 'Standard',
                  price: '₹249',
                  subtitle: 'Valid for 30 days',
                  features: [
                    'Monthly tracking target: 12.5 lakh study credits',
                    'Solo practice: 5 generated quizzes per day',
                    'Live Quiz: Host 3 times/day',
                    'Live Quiz: Play 10 times/day',
                    'Textbook-based tutoring',
                  ],
                  buttonText: 'Choose Standard',
                  tierId: 'tier_199',
                  onTap: () => _updateSubscription('tier_199'),
                ),
                const SizedBox(height: 24),

                // SYLLABUS MASTER - ₹499 (30 Days)
                _buildPlanCard(
                  title: 'Syllabus Master',
                  price: '₹499',
                  subtitle: 'Valid for 30 days',
                  features: [
                    'Monthly tracking target: 30 lakh study credits',
                    'Solo practice: 5 generated quizzes per day',
                    'Live Quiz: Host 5 times/day',
                    'Live Quiz: Play 15 times/day',
                    'Textbook-based tutoring',
                  ],
                  isPro: true,
                  buttonText: 'Choose Syllabus Master',
                  tierId: 'tier_499',
                  onTap: () => _updateSubscription('tier_499'),
                ),
                const SizedBox(height: 24),
                _buildPlanCard(
                  title: 'Premium',
                  price: '₹999',
                  subtitle: 'Valid for 30 days',
                  features: [
                    'Monthly tracking target: 80 lakh study credits',
                    'Solo practice: 5 generated quizzes per day',
                    'Textbook-based tutoring',
                    'Live Quiz: Host 5 times/day',
                    'Live Quiz: Play 15 times/day',
                  ],
                  buttonText: 'Choose Premium',
                  tierId: 'tier_999',
                  onTap: () => _updateSubscription('tier_999'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Tailwind.indigo600),
            ),
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
    bool isAvailable = true,
    String? tierId,
  }) {
    final bool isDarkCard = isPro;
    final Color textColor = isDarkCard ? Tailwind.white : Tailwind.slate800;
    final Color subtitleColor = isDarkCard
        ? Tailwind.slate200
        : Tailwind.slate500;
    final Color iconColor = isDarkCard
        ? Tailwind.emerald400
        : (isBooster ? Tailwind.amber500 : Tailwind.emerald500);
    final Color dividerColor = isDarkCard
        ? Tailwind.white.withValues(alpha: 0.2)
        : Tailwind.slate200;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDarkCard ? null : Tailwind.white,
            gradient: isDarkCard
                ? const LinearGradient(
                    colors: [Tailwind.indigo600, Tailwind.purple600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: Tailwind.rounded3Xl,
            boxShadow: isDarkCard ? Tailwind.shadowLg : Tailwind.shadowMd,
            border: isDarkCard
                ? null
                : Border.all(
                    color: isBooster ? Tailwind.amber500 : Tailwind.slate200,
                    width: isBooster ? 2 : 1,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tierId != null && _currentTier == tierId) ...[
                Text(
                  'YOUR CURRENT PLAN',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  color: isDarkCard
                      ? Tailwind.white
                      : (isBooster ? Tailwind.amber600 : Tailwind.indigo600),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                price,
                style: TextStyle(
                  color: textColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                softWrap: true,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: dividerColor, height: 1),
              const SizedBox(height: 24),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isDarkCard
                                ? Tailwind.slate100
                                : Tailwind.slate700,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ||
                          !_checkoutEnabled ||
                          !_acceptedPolicies ||
                          !isAvailable
                      ? null
                      : onTap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: isDarkCard
                        ? Tailwind.white
                        : (isBooster ? Tailwind.amber500 : Tailwind.indigo600),
                    foregroundColor: isDarkCard
                        ? Tailwind.indigo600
                        : Tailwind.white,
                    elevation: isDarkCard ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: Tailwind.roundedXl,
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
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
                isPro ? 'LARGER STUDY TARGET' : 'COMING SOON',
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
