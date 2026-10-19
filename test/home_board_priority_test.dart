import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutor_preethi/screens/home_selection_screen.dart';
import 'package:tutor_preethi/screens/board_selection_screen.dart';
import 'package:tutor_preethi/screens/student_tutorial.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      StudentTutorial.storageKey('demo'): true,
    });
    await Supabase.initialize(
      url: 'https://home-test.invalid',
      anonKey: 'sample',
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    await Supabase.instance.client.auth.recoverSession(
      jsonEncode({
        'access_token': 'sample',
        'refresh_token': 'sample',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'demo',
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
          'app_metadata': <String, dynamic>{},
          'user_metadata': {'full_name': 'Student', 'education_board': 'cbse'},
        },
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'board is first and change action opens saved board at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const HomeSelectionScreen(),
          ),
        );
        await tester.pumpAndSettle();
        final board = find.widgetWithText(
          FilledButton,
          'Choose / change board',
        );
        final learning = find.text('Start learning');
        expect(
          tester.getTopLeft(board).dy,
          lessThan(tester.getTopLeft(learning).dy),
        );
        if (scale == 1) expect(tester.getBottomRight(board).dy, lessThan(640));
        expect(find.text('Selected: CBSE'), findsOneWidget);
        await tester.ensureVisible(board);
        await tester.tap(board);
        await tester.pumpAndSettle();
        expect(find.byType(BoardSelectionScreen), findsOneWidget);
        expect(find.text('CBSE'), findsOneWidget);
        expect(find.text('Save board'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
