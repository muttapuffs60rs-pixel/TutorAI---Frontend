import '../services/referral_invite.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class ReferralsScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? load;
  final Future<void> Function(String)? claim;
  const ReferralsScreen({super.key, this.load, this.claim});
  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  final _code = TextEditingController();
  Map<String, dynamic>? _data;
  bool _busy = false;
  String? _error;
  static const _backend = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://akka-tutor-backend.onrender.com',
  );
  @override
  void initState() {
    super.initState();
    _load();
    pendingReferral().then((code) {
      if (mounted && code != null && _code.text.isEmpty) _code.text = code;
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _request([String? code]) async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Sign in required');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        await (code == null
                ? http.get(Uri.parse('$_backend/referrals'), headers: headers)
                : http.post(
                    Uri.parse('$_backend/referrals/claim'),
                    headers: headers,
                    body: jsonEncode({'code': code}),
                  ))
            .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw StateError(
          (jsonDecode(response.body) as Map)['detail'].toString(),
        );
      }
      throw StateError('Referral details are unavailable. Please retry.');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await (widget.load?.call() ?? _request());
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load referrals. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.claim != null) {
        await widget.claim!(_code.text.trim());
      } else {
        await _request(_code.text.trim());
      }
      await clearReferral();
      _code.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is StateError
              ? e.message.toString()
              : 'Could not save referral. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _amount(dynamic value) => (value ?? 0).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _panel(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE3E9EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
  );
  Widget _stat(String label, String value) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF60727A)),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Referrals & rewards'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            tooltip: 'Refresh referrals',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, bounds) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: bounds.maxWidth > 800
                ? (bounds.maxWidth - 760) / 2
                : 16,
            vertical: 24,
          ),
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              _panel([
                Text(_error!, style: const TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Retry referrals'),
                ),
              ]),
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF123D47), Color(0xFF235D66)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.card_giftcard_outlined,
                    color: Color(0xFFFFC6A5),
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Learning is better together.',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Invite a friend and earn up to 50,000 study credits when they make their first paid purchase.',
                    style: TextStyle(color: Color(0xFFD9E8EB), height: 1.5),
                  ),
                  if (data != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'YOUR REFERRAL CODE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: Color(0xFFD9E8EB),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      data['code'].toString(),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD83D13),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () => _copy(
                            referralLink(data['code'].toString()),
                            'Invitation link copied. Share it with your friend.',
                          ),
                          icon: const Icon(Icons.link),
                          label: const Text('Copy invitation link'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _copy(
                            data['code'].toString(),
                            'Referral code copied',
                          ),
                          icon: const Icon(Icons.copy, size: 17),
                          label: const Text('Copy code'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (data != null) ...[
              _panel([
                Row(
                  children: [
                    _stat('Credits saved', _amount(data['remaining'])),
                    _stat('Friends invited', '${data['invited']}'),
                    _stat('Total earned', _amount(data['earned'])),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      data['active'] == true
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                      size: 18,
                      color: const Color(0xFF237165),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['active'] == true
                            ? 'Unlocked while your paid subscription is active.'
                            : 'Locked until you activate a paid subscription. Your unused rewards stay saved.',
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
                if ((data['test_earned'] as num? ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Test rewards: ${_amount(data['test_earned'])} credits · Not spendable',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ]),
              _panel([
                _heading('Rewards for you'),
                const Text(
                  'Your friend subscribes. You earn credits.',
                  style: TextStyle(color: Color(0xFF60727A)),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, size) {
                    final width =
                        (size.maxWidth - (size.maxWidth >= 540 ? 30 : 10)) /
                        (size.maxWidth >= 540 ? 4 : 2);
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final reward in const [
                          ['₹49', '10,000', 'Coming soon'],
                          ['₹249', '20,000', 'Standard'],
                          ['₹499', '30,000', 'Syllabus Master'],
                          ['₹999', '50,000', 'Premium'],
                        ])
                          Container(
                            width: width,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  reward[1],
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB53413),
                                  ),
                                ),
                                const Text(
                                  'reward credits',
                                  style: TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reward[2],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF60727A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ]),
              _panel([
                _heading('Three simple steps'),
                for (final step in const [
                  (
                    '1',
                    'Share your link',
                    'Send your invitation link to a friend.',
                  ),
                  (
                    '2',
                    'Your friend joins',
                    'They sign up and confirm the prefilled code before paying.',
                  ),
                  (
                    '3',
                    'You earn credits',
                    'Their first successful paid purchase rewards you only.',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFFFEDE6),
                          child: Text(
                            step.$1,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB53413),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                step.$3,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF60727A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  'One reward per friend. Use rewards after your plan allowance, before top-ups. Unused rewards stay saved when your subscription expires and unlock on renewal.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF60727A),
                  ),
                ),
              ]),
              if (data['can_claim'] == true)
                _panel([
                  _heading('Have a friend’s code?'),
                  TextField(
                    controller: _code,
                    enabled: !_busy,
                    maxLength: 32,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Friend referral code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Text(
                    'Apply once, before your first payment. The code cannot be changed.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF60727A)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _claim,
                    child: const Text('Apply friend code'),
                  ),
                ])
              else if (data['claimed'] == true)
                _panel([const Text('Your friend’s referral code is saved.')]),
              _panel([
                _heading('Reward history'),
                if ((data['history'] as List).isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF94A3AA),
                          size: 32,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Your first reward starts with an invitation.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Earned credits will appear here.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF60727A),
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final row in data['history'] as List)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.card_giftcard_outlined),
                    title: Text('+${_amount(row['credits'])} credits'),
                    subtitle: Text(
                      '${DateTime.parse(row['created_at'].toString()).toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10)} · IST · ${row['mode'] == 'test' ? 'Test reward · not spendable' : 'First paid purchase'}',
                    ),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
