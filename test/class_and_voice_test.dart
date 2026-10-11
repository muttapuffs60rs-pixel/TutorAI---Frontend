import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutor_preethi/screens/subject_selection_screen.dart';
import 'package:tutor_preethi/widgets/voice_input_dialog.dart';

void main() {
  testWidgets('Tuition uses saved board and waits for class', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SubjectSelectionScreen(board: 'tn')),
    );
    expect(find.text('Tamil Nadu State Board'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Select class first'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 6').last);
    await tester.pumpAndSettle();
    expect(find.text('Tamil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'voice review defaults Tamil and returns text only on confirmation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const VoiceInputDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('தமிழ் (Tamil)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'தமிழில் ஒரு கேள்வி');
      await tester.pump();
      expect(result, isNull);
      await tester.tap(find.text('Add to message'));
      await tester.pumpAndSettle();
      expect(result, 'தமிழில் ஒரு கேள்வி');
    },
  );
}
