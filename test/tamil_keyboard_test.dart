import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/tamil_keyboard.dart';

void main() {
  test('Tamil edits preserve selection, vowel signs and emoji', () {
    final controller = TextEditingController(text: 'A தமிழ் B');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);
    editTamilDraft(controller, 'மொழி');
    expect(controller.text, 'A மொழி B');
    editTamilDraft(controller, '', backspace: true);
    expect(controller.text, 'A மொ B');
    controller.value = const TextEditingValue(
      text: 'தமிழ்👩🏽‍🏫',
      selection: TextSelection.collapsed(offset: -1),
    );
    editTamilDraft(controller, '', backspace: true);
    expect(controller.text, 'தமிழ்');
    editTamilDraft(controller, '', backspace: true);
    expect(controller.text, 'தமி');
    controller.text = '';
    editTamilDraft(controller, '', backspace: true);
    expect(controller.text, '');
  });

  testWidgets('Tamil word can be typed on a small phone and retained on Done', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: TamilKeyboard(
              controller: controller,
              onDone: () => done = true,
            ),
          ),
        ),
      ),
    );
    for (final pair in [('த', 'த'), ('ம', 'மி'), ('ழ', 'ழ்')]) {
      final choose = find.byKey(ValueKey('choose-${pair.$1}'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pumpAndSettle();
      final insert = find.byKey(ValueKey('insert-${pair.$2}'));
      await tester.ensureVisible(insert);
      await tester.tap(insert);
      await tester.pumpAndSettle();
    }
    expect(controller.text, 'தமிழ்');
    await tester.tap(find.text('Space / இடைவெளி'));
    expect(controller.text, 'தமிழ் ');
    await tester.tap(find.byTooltip('Delete previous letter'));
    expect(controller.text, 'தமிழ்');
    await tester.tap(find.text('Done'));
    expect(done, true);
    expect(controller.text, 'தமிழ்');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Forms return to letters and tabs insert vowels and punctuation',
    (tester) async {
      final controller = TextEditingController(text: 'கேள்வி');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TamilKeyboard(controller: controller, onDone: () {}),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('choose-க')));
      await tester.pump();
      expect(
        controller.text,
        'கேள்வி',
      ); // Selection alone must not change the draft.
      await tester.tap(find.byKey(const ValueKey('insert-கா')));
      await tester.pump();
      expect(controller.text, 'கேள்விகா');
      expect(find.byKey(const ValueKey('choose-க')), findsOneWidget);
      expect(find.byKey(const ValueKey('insert-கா')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tamil-tab-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('insert-ஆ')));
      await tester.tap(find.byKey(const ValueKey('tamil-tab-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('insert-?')));
      expect(controller.text, 'கேள்விகாஆ?');
      expect(tester.takeException(), isNull);
    },
  );
}
