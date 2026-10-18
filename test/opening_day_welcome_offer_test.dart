import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/opening_day_welcome_offer.dart';

void main() {
  testWidgets('offer explains total and is hidden at the IST deadline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpeningDayWelcomeOffer(
            now: DateTime.parse('2026-10-20T18:29:59Z'),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('30,000 standard + 20,000 bonus'),
      findsOneWidget,
    );
    expect(find.textContaining('No purchase needed'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpeningDayWelcomeOffer(
            now: DateTime.parse('2026-10-20T18:30:00Z'),
          ),
        ),
      ),
    );
    expect(find.byType(Card), findsNothing);
  });
  testWidgets('eligible account can see its grant after opening day', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpeningDayWelcomeOffer(
            now: DateTime.parse('2026-10-22T00:00:00Z'),
            accountCreatedAt: DateTime.parse('2026-10-19T18:30:00Z'),
          ),
        ),
      ),
    );
    expect(find.text('Your opening-day welcome grant'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpeningDayWelcomeOffer(
            now: DateTime.parse('2026-10-22T00:00:00Z'),
            accountCreatedAt: DateTime.parse('2026-10-20T18:30:00Z'),
          ),
        ),
      ),
    );
    expect(find.byType(Card), findsNothing);
  });
}
