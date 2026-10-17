import 'dart:async';
import 'package:flutter/material.dart';
import 'legal_policy_screen.dart';
import '../widgets/auxiumsoft_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps the Navigator so direct links and existing sessions are checked too.
class PrelaunchGate extends StatefulWidget {
  final Widget child;
  const PrelaunchGate({super.key, required this.child});
  @override
  State<PrelaunchGate> createState() => _PrelaunchGateState();
}

class _PrelaunchGateState extends State<PrelaunchGate>
    with WidgetsBindingObserver {
  final _client = Supabase.instance.client;
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<AuthState>? _auth;
  Timer? _poll;
  Timer? _clock;
  Map<String, dynamic>? _status;
  DateTime? _serverTime;
  final Stopwatch _elapsed = Stopwatch();
  bool _loginVisible = false, _busy = false, _checking = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = _client.auth.onAuthStateChange.listen((_) {
      _generation++;
      if (mounted) setState(() => _status = null);
      _refresh();
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _status?['allowed'] != true) setState(() {});
    });
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_checking) return;
    _checking = true;
    final generation = _generation;
    try {
      final value = await _client
          .rpc('app_launch_status')
          .timeout(const Duration(seconds: 15));
      if (!mounted || generation != _generation) return;
      if (value is! Map ||
          value['allowed'] is! bool ||
          value['prelaunch'] is! bool) {
        throw const FormatException('Invalid launch status');
      }
      final serverTime = DateTime.parse(value['server_now'] as String).toUtc();
      setState(() {
        _status = Map<String, dynamic>.from(value);
        _serverTime = serverTime;
        _elapsed.reset();
        _elapsed.start();
        _error = null;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _status = null; // Fail closed, including an already open session.
          _error = 'We could not check access. Please try again shortly.';
        });
      }
    } finally {
      _checking = false;
      if (mounted && generation != _generation) _refresh();
    }
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      _password.clear();
      await _refresh();
    } on AuthException {
      if (mounted) {
        setState(
          () => _error = 'Unable to sign in. Check your email and password.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to sign in right now. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.cancel();
    _poll?.cancel();
    _clock?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status?['allowed'] == true) return widget.child;
    final now = (_serverTime ?? DateTime.now().toUtc()).add(
      _serverTime == null ? Duration.zero : _elapsed.elapsed,
    );
    final launchDate = _status?['launch_date'] as String? ?? '2026-10-20';
    final launchAt = DateTime.tryParse(_status?['launch_at'] as String? ?? '');
    final label = launchCountdown(now, launchDate, launchAt);
    return Navigator(
      pages: [
        MaterialPage(
          child: Scaffold(
            backgroundColor: const Color(0xfff7f8fc),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/arivora_icon.png',
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Arivora',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff2854b8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A new chapter in learning',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ask doubts, practise quizzes, and study your syllabus with Arivora. '
                          'Your learning journey begins soon!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xfffff0c7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'LAUNCHING',
                                style: TextStyle(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatLaunchDate(launchDate),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff2854b8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                launchAt == null
                                    ? 'Ceremony time will be announced soon · IST'
                                    : 'Countdown to the ceremony · IST',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Public access will open when the launch is announced.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const SelectableText(
                          'Solutions@auxiumsoft.com',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const AuxiumSoftBrand(),
                        const SizedBox(height: 12),
                        const LegalPolicyLinks(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Retry access check'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_client.auth.currentSession != null) ...[
                          const Text(
                            'This account is waiting for public launch. Private access is limited to approved testers.',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () => _client.auth.signOut(),
                            child: const Text('Sign out'),
                          ),
                        ] else ...[
                          TextButton(
                            onPressed: () =>
                                setState(() => _loginVisible = !_loginVisible),
                            child: const Text('Private tester sign-in'),
                          ),
                          if (_loginVisible) ...[
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              onSubmitted: (_) => _signIn(),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _busy ? null : _signIn,
                              child: Text(_busy ? 'Signing in…' : 'Sign in'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      onDidRemovePage: (_) {},
    );
  }
}

String formatLaunchDate(String date) {
  final d = DateTime.parse(date);
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String launchCountdown(DateTime nowUtc, String date, DateTime? instant) {
  if (instant != null) {
    final left = instant.toUtc().difference(nowUtc.toUtc());
    if (left.isNegative || left.inSeconds == 0) {
      return 'Launch ceremony is near';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${left.inDays}d ${two(left.inHours % 24)}h ${two(left.inMinutes % 60)}m ${two(left.inSeconds % 60)}s';
  }
  final ist = nowUtc.toUtc().add(const Duration(hours: 5, minutes: 30));
  final today = DateTime.utc(ist.year, ist.month, ist.day);
  final target = DateTime.parse('${date}T00:00:00Z');
  final days = target.difference(today).inDays;
  if (days == 0) return 'Launch day is here';
  if (days < 0) return 'Opening soon';
  return '$days ${days == 1 ? 'day' : 'days'} to go';
}
