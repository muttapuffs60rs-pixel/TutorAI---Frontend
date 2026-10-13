import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/usage_meter.dart';

void main() {
  Map<String, dynamic> usage({int used = 610000, int unknown = 0, int? target = 1000000}) => {
    'monthly_token_target': target, 'monthly_tokens_used': used,
    'unmetered_requests': unknown, 'daily_limit': 5, 'daily_remaining': 3,
    'period_end': '2026-11-01T00:00:00+05:30',
  };
  Future<void> show(WidgetTester tester, Future<Map<String, dynamic>> Function() load) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 304,
      child: UsageMeter(loadUsage: load)))));
    await tester.pumpAndSettle();
  }
  testWidgets('Paid plan shows actual percentage and explicitly labels target', (tester) async {
    await show(tester, () async => usage());
    expect(find.text('39% left'), findsOneWidget);
    expect(find.textContaining('tracking only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Incomplete counts do not claim a remaining percentage', (tester) async {
    await show(tester, () async => usage(unknown: 1));
    expect(find.text('Incomplete'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Over target clamps to zero', (tester) async {
    await show(tester, () async => usage(used: 1200000));
    expect(find.text('0% left'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Paid meter deducts saved-answer credits despite zero API tokens', (tester) async {
    await show(tester, () async => {...usage(used: 0), 'monthly_credits_used': 3000});
    expect(find.text('0.3% used'), findsOneWidget);
    expect(find.text('99.7% left'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Trial shows lifetime allowance without monthly reset', (tester) async {
    await show(tester, () async => {...usage(used: 10000),
      'token_target': 50000, 'token_period': 'lifetime'});
    expect(find.text('80% left'), findsOneWidget);
    expect(find.textContaining('No monthly reset'), findsOneWidget);
    expect(find.textContaining('New period:'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Free credits show welcome percentage without daily refill', (tester) async {
    await show(tester, () async => {...usage(), 'learning_credits': {
      'daily_remaining': 3000, 'welcome_remaining': 46000,
      'active': false, 'completion_overrun': 0,
    }});
    expect(find.text('Token usage'), findsOneWidget);
    expect(find.textContaining('left today'), findsNothing);
    expect(find.textContaining('used today'), findsNothing);
    expect(find.text('8% of welcome credits used'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.92);
    expect(find.textContaining('3000 /'), findsNothing);
    expect(find.textContaining('46000'), findsNothing);
    expect(find.text('Welcome allowance: 92% left'), findsOneWidget);
    expect(find.textContaining('Saved answer:'), findsNothing);
    expect(find.textContaining('tracking only'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Exhausted welcome credits stay zero while top-ups remain visible', (tester) async {
    await show(tester, () async => {...usage(), 'learning_credits': {
      'daily_remaining': 0, 'daily_allowance': 0, 'welcome_remaining': 0,
      'welcome_allowance': 50000, 'topup_remaining': 12000, 'resets_at': null,
    }});
    expect(find.text('Welcome allowance: 0% left'), findsOneWidget);
    expect(find.text('Top-up balance available'), findsOneWidget);
    expect(find.textContaining('midnight'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Missing token allowance never falls back to question counts', (tester) async {
    await show(tester, () async => usage(target: null));
    expect(find.text('Tracking'), findsOneWidget);
    expect(find.textContaining('questions left'), findsNothing);
    expect(find.text('Percentage unavailable without an allowance.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Failure is unavailable, retry recovers without fake zero', (tester) async {
    var attempts = 0;
    await show(tester, () async {
      if (attempts++ == 0) throw StateError('offline');
      return usage();
    });
    expect(find.text('Usage unavailable'), findsOneWidget);
    await tester.tap(find.byTooltip('Retry usage'));
    await tester.pumpAndSettle();
    expect(find.text('39% left'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
