import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'legal_policy_screen.dart';

const acceptanceVersion = '2026-10-20';

bool hasAcceptedPolicies(Map<String, dynamic>? data) =>
    data?['terms_accepted_version'] == acceptanceVersion &&
    data?['refunds_accepted_version'] == acceptanceVersion;

/// Wraps every route, including direct links and restored sessions.
class PolicyAcceptanceGate extends StatelessWidget {
  final Widget child;
  const PolicyAcceptanceGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = client.auth.currentUser;
        if (user == null || hasAcceptedPolicies(user.userMetadata)) {
          return child;
        }
        return Navigator(
          key: ValueKey('policies-${user.id}'),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => PolicyAcceptanceScreen(
              onAccept: () async {
                if (client.auth.currentUser?.id != user.id) {
                  throw StateError('Account changed');
                }
                await client.auth.updateUser(
                  UserAttributes(
                    data: {
                      'terms_accepted_version': acceptanceVersion,
                      'refunds_accepted_version': acceptanceVersion,
                      'policies_accepted_at': DateTime.now()
                          .toUtc()
                          .toIso8601String(),
                    },
                  ),
                );
              },
              onSignOut: () => client.auth.signOut(),
            ),
          ),
        );
      },
    );
  }
}

class PolicyAcceptanceScreen extends StatefulWidget {
  final Future<void> Function() onAccept;
  final Future<void> Function() onSignOut;
  const PolicyAcceptanceScreen({
    super.key,
    required this.onAccept,
    required this.onSignOut,
  });
  @override
  State<PolicyAcceptanceScreen> createState() => _PolicyAcceptanceScreenState();
}

class _PolicyAcceptanceScreenState extends State<PolicyAcceptanceScreen> {
  bool _terms = false, _refunds = false, _busy = false;
  String? _error;
  Future<void> _save() async {
    if (!_terms || !_refunds || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onAccept();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save your acceptance. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Before you continue'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome to Arivora',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please review and accept both policies before continuing. If you are under 18, ask your parent or guardian to review them with you.',
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () =>
                      LegalPolicyScreen.open(context, LegalPolicy.terms),
                  child: const Text('Read Terms and Conditions'),
                ),
                CheckboxListTile(
                  value: _terms,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _terms = v ?? false),
                  title: const Text('I accept the Terms and Conditions.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                OutlinedButton(
                  onPressed: () =>
                      LegalPolicyScreen.open(context, LegalPolicy.refunds),
                  child: const Text('Read Cancellation and Refund Policy'),
                ),
                CheckboxListTile(
                  value: _refunds,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _refunds = v ?? false),
                  title: const Text(
                    'I accept the Cancellation and Refund Policy.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const Text(
                  'If I am under 18, I confirm that my parent or guardian has authorised my use of Arivora.',
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  onPressed: _terms && _refunds && !_busy ? _save : null,
                  child: Text(_busy ? 'Saving...' : 'Accept and continue'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          try {
                            await widget.onSignOut();
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => _error =
                                    'Could not sign out. Please try again.',
                              );
                            }
                          }
                        },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
