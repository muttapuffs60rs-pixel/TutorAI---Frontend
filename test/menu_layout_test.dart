import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutor_preethi/widgets/custom_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk != null) {
      for (final entry in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key);
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              await File(
                '$sdk/bin/cache/artifacts/material_fonts/${entry.value}',
              ).readAsBytes(),
            ),
          ),
        );
        await loader.load();
      }
    }
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://menu-test.invalid',
      anonKey: 'synthetic-test',
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> openMenu(
    WidgetTester tester, {
    double width = 360,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Arivora')),
            drawer: CustomDrawer(
              subscriptionTier: 'tier_199',
              subscriptionExpiresAt: '2026-11-15T18:29:59Z',
              loadUsage: () async => {
                'monthly_token_target': 1000000,
                'monthly_tokens_used': 40000,
                'unmetered_requests': 0,
                'period_end': '2026-11-15T18:29:59Z',
              },
            ),
            body: const Center(child: Text('Your lessons')),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Phone menu keeps plan visible and all actions scroll into view',
    (tester) async {
      await openMenu(tester);
      expect(find.text('Standard plan'), findsOneWidget);
      expect(find.text('96% left'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/menu_mobile.png'),
      );
      await tester.scrollUntilVisible(
        find.text('Cancellation & refunds'),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(ListView).last, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancellation & refunds'));
      await tester.pumpAndSettle();
      expect(
        find.text('1. Cancelling a purchase or future access'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Menu remains usable with large text on a narrow phone', (
    tester,
  ) async {
    await openMenu(tester, width: 320, textScale: 1.4);
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('menu Contact support opens an in-app contact page', (
    tester,
  ) async {
    await openMenu(tester);
    await tester.scrollUntilVisible(
      find.text('Contact support'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();
    expect(find.text('Copy email address'), findsOneWidget);
    expect(find.text('Tell us what happened'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your lessons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
