// Regenerate real application captures with:
// flutter test test/tutorial_capture_test.dart --dart-define=CAPTURE_TUTORIAL=true
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutor_preethi/main.dart';
import 'package:tutor_preethi/screens/home_selection_screen.dart';
import 'package:tutor_preethi/screens/subject_selection_screen.dart';
import 'package:tutor_preethi/screens/chat_screen.dart';
import 'package:tutor_preethi/screens/solo_practice_screen.dart';
import 'package:tutor_preethi/screens/live_quiz/student_join_screen.dart';
import 'package:tutor_preethi/screens/student_tutorial.dart';
import 'package:tutor_preethi/widgets/custom_drawer.dart';

void main() {
  testWidgets(
    'capture tutorial screens with synthetic data',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        StudentTutorial.storageKey('demo'): true,
      });
      await Supabase.initialize(
        url: 'https://tutorial.invalid',
        anonKey: 'sample',
        authOptions: const FlutterAuthClientOptions(
          detectSessionInUri: false,
          autoRefreshToken: false,
        ),
        httpClient: MockClient(
          (_) async => http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(() => Supabase.instance.dispose());
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      for (final entry in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
      }.entries) {
        final font = FontLoader(entry.key);
        font.addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/${entry.value}',
              ).readAsBytesSync(),
            ),
          ),
        );
        await font.load();
      }
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final captures = <Map<String, dynamic>>[];
      Future<void> mount(Widget page) async {
        await tester.pumpWidget(const SizedBox());
        final theme =
            (const AkkaApp().build(tester.element(find.byType(SizedBox).first))
                    as MaterialApp)
                .theme!;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
              appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            home: RepaintBoundary(key: boundary, child: page),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name, Finder target, String label) async {
        final rect = tester.getRect(target);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(800));
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final pixels = await render.toImage(pixelRatio: 2);
          final bytes = (await pixels.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await Directory('assets/tutorial').create(recursive: true);
          await File(
            'assets/tutorial/$name.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          pixels.dispose();
        });
        captures.add({
          'asset': 'assets/tutorial/$name.png',
          'label': label,
          'rect': [
            rect.left / 400,
            rect.top / 800,
            rect.width / 400,
            rect.height / 800,
          ],
        });
      }

      final auth = Supabase.instance.client.auth;
      // Synthetic in-memory identity; all Supabase requests use the local mock.
      await auth.recoverSession(
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
            'user_metadata': {'full_name': 'Student', 'education_board': 'tn'},
          },
        }),
      );
      await mount(const HomeSelectionScreen());
      await capture(
        'home',
        find.widgetWithText(ElevatedButton, 'Start learning'),
        'Tap Start learning',
      );
      await mount(const SubjectSelectionScreen(board: 'tn'));
      await capture(
        'class',
        find.byType(DropdownButtonFormField<int>),
        'Choose your class',
      );
      // An unsigned preview avoids creating any chat session.
      await auth.signOut(scope: SignOutScope.local);
      await mount(
        const ChatScreen(initialSubject: 'Science', initialGradeLevel: 6),
      );
      await tester.enterText(
        find.byType(TextField).last,
        'Explain evaporation with an example.',
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();
      await capture(
        'chat',
        find.byTooltip('Send question'),
        'Type a question, then tap Send',
      );
      await mount(const SoloPracticeScreen());
      await tester.ensureVisible(find.text('Start practice'));
      await tester.pumpAndSettle();
      await capture(
        'practice',
        find.widgetWithText(FilledButton, 'Start practice'),
        'Choose a topic, then tap Start practice',
      );
      await mount(const StudentJoinScreen());
      await capture(
        'join',
        find.text('JOIN NOW'),
        'Enter your teacher’s PIN and name, then tap JOIN NOW',
      );
      await mount(
        Scaffold(
          appBar: AppBar(title: const Text('Arivora')),
          drawer: CustomDrawer(
            loadUsage: () async => {
              'monthly_token_target': 1000000,
              'monthly_tokens_used': 40000,
              'unmetered_requests': 0,
              'period_end': '2026-11-15T18:29:59Z',
            },
          ),
          body: const SizedBox(),
        ),
      );
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('My profile'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await capture(
        'menu',
        find.text('My profile'),
        'Open My profile for your account and credit history',
      );
      captures.add(captures.first);
      await tester.runAsync(() async {
        final json = const JsonEncoder.withIndent('  ').convert(captures);
        await File('assets/tutorial/captures.json').writeAsString(json);
        await File('lib/screens/tutorial_captures.dart').writeAsString(
          '// Generated by tutorial_capture_test.dart. Re-capture when these screens change.\n'
          'const tutorialCaptures = <Map<String, dynamic>>$json;\n',
        );
      });
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('CAPTURE_TUTORIAL'),
  );
}
