import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/student_profile_screen.dart';
import 'package:tutor_preethi/services/student_profile_store.dart';

class FakeStudentProfileStore implements StudentProfileStore {
  Map<String, dynamic> data = {
    'name': 'Sample student',
    'email': 'student@example.invalid',
    'joined_at': '2026-10-01T12:00:00Z',
    'board': 'tn',
    'subscription_tier': 'tier_199',
    'subscription_expires_at': '2099-01-01T00:00:00Z',
    'date_of_birth': '2012-02-29',
  };
  bool failAccount = false, failCredits = false;
  final List<int> creditOffsets = [];
  @override
  Future<Map<String, dynamic>> account() async {
    if (failAccount) throw StateError('offline');
    return Map.from(data);
  }

  @override
  Future<void> saveDetails(String name, String? dateOfBirth) async {
    data['name'] = name;
    data['date_of_birth'] = dateOfBirth;
  }

  @override
  Future<void> saveBoard(String board) async {
    data['board'] = board;
  }

  @override
  Future<List<Map<String, dynamic>>> learning(int offset) async => [
    {
      'id': 'synthetic-session',
      'title': 'Algebra practice',
      'subject': 'Maths',
      'grade_level': 10,
      'board': 'tn',
      'created_at': '2026-10-18T09:00:00Z',
    },
  ];
  @override
  Future<Map<String, dynamic>> credits(int offset) async {
    creditOffsets.add(offset);
    if (failCredits) throw StateError('offline');
    return {
      'has_more': offset == 0,
      'items': [
        {
          'id': 'usage-$offset',
          'created_at': '2026-10-18T09:00:00Z',
          'credits_used': offset == 0 ? 3000 : 1500,
          'kind': 'Tutor request',
        },
      ],
    };
  }
}

void main() {
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
  });
  Future<void> open(WidgetTester tester, FakeStudentProfileStore store) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: StudentProfileScreen(
          store: store,
          loadUsage: () async => {
            'monthly_token_target': 1250000,
            'monthly_tokens_used': 25000,
            'unmetered_requests': 0,
            'period_end': '2026-11-01T00:00:00Z',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('birth dates require a real, past, full date', () {
    expect(validBirthDate('2012-02-29'), DateTime(2012, 2, 29));
    for (final value in ['2011-02-29', '2099-01-01', '1800-01-01', '', null]) {
      expect(validBirthDate(value), isNull);
    }
  });
  testWidgets('profile overview fits a phone with a full DOB', (tester) async {
    await open(tester, FakeStudentProfileStore());
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/student_profile_mobile.png'),
    );
  });
  testWidgets('profile shows own history and paginated credit usage', (
    tester,
  ) async {
    final store = FakeStudentProfileStore();
    await open(tester, store);
    expect(find.text('Sample student'), findsOneWidget);
    expect(find.text('Date of birth: 29 February 2012'), findsOneWidget);
    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Algebra practice'), findsOneWidget);
    await tester.tap(find.text('Credits'));
    await tester.pumpAndSettle();
    expect(find.text('3000 study credits used'), findsOneWidget);
    await tester.ensureVisible(find.text('Load older records'));
    await tester.tap(find.text('Load older records'));
    await tester.pumpAndSettle();
    expect(store.creditOffsets, [0, 1]);
    expect(find.text('1500 study credits used'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'editing can remove optional DOB without changing account email',
    (tester) async {
      final store = FakeStudentProfileStore();
      await open(tester, store);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New display name');
      await tester.tap(find.text('Remove date of birth'));
      await tester.ensureVisible(find.text('Save profile'));
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(store.data['date_of_birth'], isNull);
      expect(store.data['email'], 'student@example.invalid');
      expect(find.text('New display name'), findsOneWidget);
      expect(find.text('Date of birth: Not added (optional)'), findsOneWidget);
    },
  );
  testWidgets('profile and credit errors can be retried', (tester) async {
    final store = FakeStudentProfileStore()..failAccount = true;
    await open(tester, store);
    expect(find.text('Retry profile'), findsOneWidget);
    store.failAccount = false;
    await tester.tap(find.text('Retry profile'));
    await tester.pumpAndSettle();
    store.failCredits = true;
    await tester.tap(find.text('Credits'));
    await tester.pumpAndSettle();
    expect(find.text('Retry history'), findsOneWidget);
    store.failCredits = false;
    await tester.tap(find.text('Retry history'));
    await tester.pumpAndSettle();
    expect(find.text('3000 study credits used'), findsOneWidget);
  });
}
