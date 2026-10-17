import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/subscription_screen.dart';

void main() {
  setUpAll(() async {
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk != null) {
      final loader = FontLoader('Roboto');
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            await File(
              '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
            ).readAsBytes(),
          ),
        ),
      );
      await loader.load();
    }
  });
  testWidgets(
    'plan comparison fits a narrow phone and handles an expired plan',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: SubscriptionScreen(
            profileLoader: () async => {
              'subscription_tier': 'tier_199',
              'subscription_expires_at': '2020-01-01T00:00:00Z',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your current plan: Free'), findsOneWidget);
      expect(find.text('YOUR CURRENT PLAN'), findsNothing);
      await tester.ensureVisible(find.byType(Table));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/plan_comparison_mobile.png'),
      );
    },
  );
}
