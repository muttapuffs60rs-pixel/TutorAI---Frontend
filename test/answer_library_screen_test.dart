import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/answer_library_screen.dart';
import 'package:tutor_preethi/services/answer_library_service.dart';

final candidate = <String, dynamic>{
  'id': 'entry',
  'question': 'What is gravity?',
  'answer': 'An attractive force.',
  'grade_level': 10,
  'subject': 'Science',
  'language': 'Tanglish',
  'board': 'Tamil Nadu State Board',
  'syllabus_version': '2026-v1',
  'updated_at': '2026-10-08T00:00:00Z',
  'report_count': 0,
};

class FakeLibrary extends AnswerLibraryService {
  Map<String, dynamic>? saved;
  bool fail = false;
  @override
  Future<List<Map<String, dynamic>>> list(String status, int offset) async {
    if (fail) throw StateError('Offline');
    return [candidate];
  }

  @override
  Future<void> review(String id, Map<String, dynamic> review) async {
    saved = review;
  }
}

void main() {
  testWidgets(
    'review requires checks and sends edited answer with original revision',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = FakeLibrary();
      await tester.pumpWidget(
        MaterialApp(home: AnswerLibraryScreen(service: service)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('What is gravity?'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Approve answer'));
      await tester.tap(find.text('Approve answer'));
      await tester.pumpAndSettle();
      expect(service.saved, isNull);
      expect(find.textContaining('Approval requires'), findsOneWidget);

      for (final pair in [
        (0, 'Reviewed explanation'),
        (1, 'Gravitation'),
        (2, '2026 textbook, page 10'),
      ]) {
        final field = find.byType(TextField).at(pair.$1);
        await tester.ensureVisible(field);
        await tester.enterText(field, pair.$2);
      }
      for (var index = 0; index < 2; index++) {
        final check = find.byType(CheckboxListTile).at(index);
        await tester.ensureVisible(check);
        await tester.tap(check);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Approve answer'));
      await tester.tap(find.text('Approve answer'));
      await tester.pumpAndSettle();
      expect(service.saved?['status'], 'approved');
      expect(service.saved?['answer'], 'Reviewed explanation');
      expect(service.saved?['expected_updated_at'], candidate['updated_at']);
      expect(service.saved?['privacy_checked'], isTrue);
      expect(find.text('Answer library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed library load offers refresh and recovers', (
    tester,
  ) async {
    final service = FakeLibrary()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: AnswerLibraryScreen(service: service)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('What is gravity?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
