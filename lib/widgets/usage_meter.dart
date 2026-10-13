import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../theme/tailwind_theme.dart';

/// Compact account usage card. Monthly figures are tracking targets, not a wallet.
class UsageMeter extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loadUsage;
  const UsageMeter({super.key, this.loadUsage});
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
        if (mounted) setState(() { _usage = data; _failed = false; _loading = false; });
        return;
      }
      final token = supabase.auth.currentSession?.accessToken;
      if (token == null) throw StateError('Sign in required');
      final response = await http.get(
        Uri.parse('https://akka-tutor-backend.onrender.com/usage'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Usage unavailable');
      final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      if (mounted) setState(() { _usage = data; _failed = false; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _failed = true; _loading = false; });
    } finally {
      _inFlight = false;
    }
  }

  String _percent(double fraction) => (fraction * 100).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  @override
  Widget build(BuildContext context) {
    final data = _usage;
    if (_loading) {
      return const ListTile(leading: Icon(Icons.speed), title: Text('Loading usage…'));
    }
    if (_failed || data == null) {
      return ListTile(leading: const Icon(Icons.speed), title: const Text('Usage unavailable'),
        trailing: IconButton(onPressed: _load, tooltip: 'Retry usage', icon: const Icon(Icons.refresh)));
    }
    if (data['learning_credits'] is Map) {
      final credits = Map<String, dynamic>.from(data['learning_credits'] as Map);
      final welcome = (credits['welcome_remaining'] as num).toInt();
      final allowance = (credits['welcome_allowance'] as num?) ?? 50000;
      final welcomeFraction = allowance > 0 ? (welcome / allowance).clamp(0.0, 1.0) : null;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Tailwind.indigo50, borderRadius: Tailwind.roundedXl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.speed_outlined, size: 20), SizedBox(width: 8),
            Expanded(child: Text('Token usage', style: TextStyle(fontWeight: FontWeight.w600)))]),
          const SizedBox(height: 8),
          Text(welcomeFraction == null ? 'Welcome allowance unavailable' : 'Welcome allowance: ${_percent(welcomeFraction)}% left'),
          const SizedBox(height: 8),
          if (welcomeFraction != null) LinearProgressIndicator(value: welcomeFraction, minHeight: 5),
          const SizedBox(height: 8),
          if (welcomeFraction != null) Text('${_percent(1 - welcomeFraction)}% of welcome credits used'),
          if ((credits['topup_remaining'] as num? ?? 0) > 0)
            const Text('Top-up balance available'),
          const SizedBox(height: 8),
          const Text('50,000 welcome credits, once per new account. No daily refill.',
            style: TextStyle(fontSize: 11, color: Colors.black54)),
          if (credits['active'] == true) const Text('Answer in progress; balance updates when it finishes.', style: TextStyle(fontSize: 11)),
          if ((credits['completion_overrun'] as num? ?? 0) > 0)
            const Text('Your available balance accounts for credits used to finish your last answer.', style: TextStyle(fontSize: 11)),
          Align(alignment: Alignment.centerRight, child: IconButton(onPressed: _load,
            tooltip: 'Refresh usage', icon: const Icon(Icons.refresh, size: 18))),
        ]),
      );
    }
    final target = (data['token_target'] ?? data['monthly_token_target']) as int?;
    final lifetime = data['token_period'] == 'lifetime';
    final unknown = (data['unmetered_requests'] as int? ?? 0) > 0;
    final used = (data['monthly_credits_used'] ?? data['monthly_tokens_used']) as int;
    final remaining = target == null ? null : (target - used).clamp(0, target);
    final fraction = target == null || target == 0 ? null : (remaining! / target).clamp(0.0, 1.0);
    final percentage = fraction == null ? null : _percent(fraction);
    final color = fraction != null && fraction <= .2 ? Colors.orange.shade800 : Tailwind.indigo600;
    final end = DateTime.parse(data['period_end'] as String);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Tailwind.indigo50, borderRadius: Tailwind.roundedXl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.speed_outlined, size: 21), const SizedBox(width: 8),
          const Expanded(child: Text('Token usage', style: TextStyle(fontWeight: FontWeight.w600))),
          Text(target != null && unknown ? 'Incomplete' : percentage == null ? 'Tracking' : '$percentage% left',
            style: TextStyle(color: color)),
        ]),
        const SizedBox(height: 10),
        if (fraction != null && !(target != null && unknown)) ...[
          LinearProgressIndicator(value: fraction, minHeight: 5, color: color,
            backgroundColor: Colors.black12, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 10),
        ],
        Text(unknown ? 'Usage is still being calculated.' : fraction == null
          ? 'Percentage unavailable without an allowance.'
          : '${_percent(1 - fraction)}% used', style: const TextStyle(fontSize: 12)),
        if (target != null) ...[
          const SizedBox(height: 4),
          Text(lifetime ? 'One-time free trial · tracking only\nNo monthly reset' : 'Monthly target · tracking only\nNew period: ${end.day}/${end.month}/${end.year} (IST)',
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
        if ((data['topup_remaining'] as num? ?? 0) > 0)
          const Text('Top-up balance available', style: TextStyle(fontSize: 12)),
        if (unknown) const Padding(padding: EdgeInsets.only(top: 4),
          child: Text('Some requests have no final token count yet.', style: TextStyle(fontSize: 11))),
        Align(alignment: Alignment.centerRight, child: IconButton(tooltip: 'Refresh usage',
          onPressed: _load, icon: const Icon(Icons.refresh, size: 18))),
      ]),
    );
  }
}
