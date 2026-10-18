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
  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Invite a friend. Earn study credits.',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ask your friend to sign up, open My profile → Referrals & rewards, and enter your code before their first payment. Only you receive the reward after their first successful paid purchase.',
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Retry referrals'),
            ),
          ],
          if (data != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your referral code'),
                    SelectableText(
                      data['code'].toString(),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: data['code'].toString()),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral code copied'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy code'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reward credits saved: ${_amount(data['remaining'])}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              data['active'] == true
                  ? 'Unlocked while your paid subscription is active.'
                  : 'Locked until you activate a paid subscription. Your unused rewards stay saved.',
            ),
            Text(
              'Invited students: ${data['invited']} · Total earned: ${_amount(data['earned'])} credits',
            ),
            if ((data['test_earned'] as num? ?? 0) > 0)
              Text(
                'Test rewards: ${_amount(data['test_earned'])} credits · Sandbox only, cannot be spent.',
              ),
            const SizedBox(height: 20),
            if (data['can_claim'] == true) ...[
              const Text(
                'Have a friend’s code?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                'You can add a code once, before your first payment. It cannot be changed.',
              ),
              FilledButton(
                onPressed: _busy ? null : _claim,
                child: const Text('Apply friend code'),
              ),
            ] else
              Text(
                data['claimed'] == true
                    ? 'Your friend’s referral code is saved.'
                    : 'Referral codes must be applied before your first payment.',
              ),
            const Divider(height: 32),
            const Text(
              'Rewards for the inviter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              '₹49 → 10,000 credits\n₹249 → 20,000 credits\n₹499 → 30,000 credits\n₹999 → 50,000 credits',
            ),
            const Text(
              'One reward per referred student, on their first verified purchase. ₹49 checkout is not currently available. Rewards are used after the plan allowance, before top-up credits. Unused rewards unlock again on renewal.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Reward history',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if ((data['history'] as List).isEmpty)
              const Text('No referral rewards yet.'),
            for (final row in data['history'] as List)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.card_giftcard),
                title: Text('+${_amount(row['credits'])} credits'),
                subtitle: Text(
                  '${DateTime.parse(row['created_at'].toString()).toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10)} · ${row['mode'] == 'test' ? 'Test reward · not spendable' : 'First paid purchase'}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
