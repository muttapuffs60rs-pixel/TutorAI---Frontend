import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../theme/tailwind_theme.dart';

/// Compact account usage card. Monthly figures are tracking targets, not a wallet.
class UsageMeter extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loadUsage;
  final bool edgeToEdge;
  const UsageMeter({super.key, this.loadUsage, this.edgeToEdge = false});
  @override
  State<UsageMeter> createState() => _UsageMeterState();
}

class _UsageMeterState extends State<UsageMeter> {
  Map<String, dynamic>? _usage;
  bool _loading = true;
  bool _failed = false;
  Timer? _timer;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && (Scaffold.maybeOf(context)?.isDrawerOpen ?? false)) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (widget.loadUsage != null) {
        final data = await widget.loadUsage!();
        if (mounted) {
          setState(() {
            _usage = data;
            _failed = false;
            _loading = false;
          });
        }
        return;
      }
      final token = supabase.auth.currentSession?.accessToken;
      if (token == null) throw StateError('Sign in required');
      final response = await http
          .get(
            Uri.parse('https://akka-tutor-backend.onrender.com/usage'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Usage unavailable');
      final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      if (mounted) {
        setState(() {
          _usage = data;
          _failed = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } finally {
      _inFlight = false;
    }
  }

  String _percent(double fraction) =>
      (fraction * 100).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  @override
  Widget build(BuildContext context) {
    final data = _usage;
    if (_loading) {
      return const ListTile(
        leading: Icon(Icons.speed),
        title: Text('Loading usage…'),
      );
    }
    if (_failed || data == null) {
      return ListTile(
        leading: const Icon(Icons.speed),
        title: const Text('Usage unavailable'),
        trailing: IconButton(
          onPressed: _load,
          tooltip: 'Retry usage',
          icon: const Icon(Icons.refresh),
        ),
      );
    }
    if (data['learning_credits'] is Map) {
      final credits = Map<String, dynamic>.from(
        data['learning_credits'] as Map,
      );
      final daily = (credits['daily_remaining'] as num).toInt();
      final welcome = (credits['welcome_remaining'] as num).toInt();
      final allowance = (credits['daily_allowance'] as num?) ?? 15000;
      final fraction = allowance > 0
          ? (daily / allowance).clamp(0.0, 1.0)
          : null;
      final welcomeAllowance = (credits['welcome_allowance'] as num?) ?? 30000;
      final welcomeFraction = welcomeAllowance > 0
          ? (welcome / welcomeAllowance).clamp(0.0, 1.0)
          : 0.0;
      return Container(
        margin: widget.edgeToEdge
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Tailwind.slate200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed_outlined, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Study allowance',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fraction == null
                  ? 'Daily usage unavailable'
                  : '${_percent(fraction)}% left today',
            ),
            const SizedBox(height: 8),
            if (fraction != null)
              LinearProgressIndicator(value: fraction, minHeight: 5),
            const SizedBox(height: 8),
            if (fraction != null) Text('${_percent(1 - fraction)}% used today'),
            Text('Welcome allowance: ${_percent(welcomeFraction)}% left'),
            if ((credits['topup_remaining'] as num? ?? 0) > 0)
              const Text('Top-up balance available'),
            const SizedBox(height: 8),
            const Text(
              'Daily allowance resets at midnight IST. Welcome allowance does not reset.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            if (credits['active'] == true)
              const Text(
                'Answer in progress; balance updates when it finishes.',
                style: TextStyle(fontSize: 11),
              ),
            if ((credits['completion_overrun'] as num? ?? 0) > 0)
              const Text(
                'Credits used to finish your last answer will be deducted from the next daily allowance.',
                style: TextStyle(fontSize: 11),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _load,
                tooltip: 'Refresh usage',
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ),
          ],
        ),
      );
    }
    final target =
        (data['token_target'] ?? data['monthly_token_target']) as int?;
    final lifetime = data['token_period'] == 'lifetime';
    final unknown = (data['unmetered_requests'] as int? ?? 0) > 0;
    final used =
        (data['monthly_credits_used'] ?? data['monthly_tokens_used']) as int;
    final remaining = target == null ? null : (target - used).clamp(0, target);
    final fraction = target == null || target == 0
        ? null
        : (remaining! / target).clamp(0.0, 1.0);
    final percentage = fraction == null ? null : _percent(fraction);
    final color = fraction != null && fraction <= .2
        ? Colors.orange.shade800
        : Tailwind.indigo600;
    return Container(
      margin: widget.edgeToEdge
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Tailwind.slate200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Study allowance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Tailwind.slate800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh usage',
                onPressed: _load,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          Text(
            target != null && unknown
                ? 'Incomplete'
                : percentage == null
                ? 'Tracking'
                : '$percentage% left',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (fraction != null && !unknown) ...[
            LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: color,
              backgroundColor: Tailwind.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            unknown
                ? 'Usage is still being calculated.'
                : fraction == null
                ? 'Percentage unavailable without an allowance.'
                : '${_percent(1 - fraction)}% used',
            style: const TextStyle(fontSize: 13, color: Tailwind.slate600),
          ),
          if (target != null) ...[
            const SizedBox(height: 10),
            if (lifetime) ...[
              const Text(
                'One-time free trial · No monthly reset',
                style: TextStyle(fontSize: 12, color: Tailwind.slate600),
              ),
              const SizedBox(height: 4),
            ],
            const Text(
              'Usage tracking only · not a billing balance',
              style: TextStyle(fontSize: 11, color: Tailwind.slate500),
            ),
          ],
          if ((data['topup_remaining'] as num? ?? 0) > 0) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Tailwind.emerald600,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Top-up balance available',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (unknown)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Some requests have no final token count yet.',
                style: TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
