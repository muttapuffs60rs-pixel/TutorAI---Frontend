import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutor_preethi/screens/prelaunch_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  bool allowed = false;
  bool unavailable = false;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://prelaunch.test', anonKey: 'test-key',
      httpClient: MockClient((request) async => unavailable
        ? http.Response('{"message":"unavailable"}', 503, request: request, headers: {'content-type':'application/json'})
        : http.Response(jsonEncode({'allowed':allowed,'prelaunch':true,'launch_date':'2026-10-20',
            'launch_at':null,'server_now':'2026-10-14T00:00:00Z'}),200,request:request,headers:{'content-type':'application/json'})),
    );
  });
  tearDownAll(() async => Supabase.instance.dispose());
  testWidgets('public deep link stays gated and tester form can receive input', (tester) async {
    allowed=false; unavailable=false;
    await tester.pumpWidget(MaterialApp(builder: (context, child) => PrelaunchGate(child: child!),
      home: const Scaffold(body: Text('PRIVATE HOME'))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE HOME'), findsNothing);
    expect(find.text('6 days to go'), findsOneWidget);
    await tester.ensureVisible(find.text('Private tester sign-in'));
    await tester.tap(find.text('Private tester sign-in'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first,'tester@example.com');
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('server-approved account reaches app', (tester) async {
    allowed=true; unavailable=false;
    await tester.pumpWidget(const MaterialApp(home: PrelaunchGate(child: Text('PRIVATE HOME'))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE HOME'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed access check does not expose app', (tester) async {
    unavailable=true;
    await tester.pumpWidget(const MaterialApp(home: PrelaunchGate(child: Text('PRIVATE HOME'))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE HOME'), findsNothing);
    expect(find.text('Retry access check'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  test('days-only counter uses IST calendar dates', () {
    expect(
      launchCountdown(
        DateTime.parse('2026-10-14T10:00:00Z'),
        '2026-10-20',
        null,
      ),
      '6 days to go',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-18T18:30:00Z'),
        '2026-10-20',
        null,
      ),
      '1 day to go',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-19T18:30:00Z'),
        '2026-10-20',
        null,
      ),
      'Launch day is here',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-21T00:00:00Z'),
        '2026-10-20',
        null,
      ),
      'Opening soon',
    );
  });
  test('confirmed instant enables exact counter without negative time', () {
    final target = DateTime.parse('2026-10-20T10:00:00+05:30');
    expect(
      launchCountdown(
        DateTime.parse('2026-10-20T04:29:00Z'),
        '2026-10-20',
        target,
      ),
      '0d 00h 01m 00s',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-20T04:30:01Z'),
        '2026-10-20',
        target,
      ),
      'Launch ceremony is near',
    );
  });
  test('launch date is readable', () {
    expect(formatLaunchDate('2026-10-20'), '20 October 2026');
  });
}
