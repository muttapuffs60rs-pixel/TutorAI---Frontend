import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/widgets/question_photo_crop.dart';

Future<Uint8List> photo() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 200, 200),
    Paint()..color = Colors.red,
  );
  canvas.drawRect(
    const Rect.fromLTWH(200, 0, 200, 200),
    Paint()..color = Colors.blue,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  for (final scenario in [
    'resize',
    'corner',
    'narrow',
    'move',
    'reset',
    'rotate',
    'cancel',
  ]) {
    testWidgets('crop supports $scenario with modal semantics enabled', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        if (scenario == 'narrow') {
          tester.view.physicalSize = const Size(390, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        final bytes = (await tester.runAsync(photo))!;
        Uint8List? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<Uint8List>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => QuestionPhotoCrop(bytes: bytes),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        final surface = find.byKey(const ValueKey('question-crop-surface'));
        expect(surface, findsOneWidget);
        final area = tester.getRect(surface);
        final width = (area.height - 48) * 2 < area.width - 48
            ? (area.height - 48) * 2
            : area.width - 48;
        final frame = Rect.fromCenter(
          center: area.center,
          width: width,
          height: width / 2,
        );
        if (scenario == 'cancel') {
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(result, isNull);
          expect(surface, findsNothing);
          return;
        }
        if (scenario == 'rotate') {
          await tester.tap(find.text('Rotate'));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pumpAndSettle();
        } else if (scenario == 'corner') {
          await tester.dragFrom(
            frame.topLeft,
            Offset(frame.width / 4, frame.height / 2),
          );
          await tester.pumpAndSettle();
        } else {
          // Resize using an edge, then move the remaining half to the blue side.
          await tester.dragFrom(frame.centerRight, Offset(-frame.width / 2, 0));
          await tester.pumpAndSettle();
          if (scenario == 'move') {
            await tester.dragFrom(
              Offset(frame.left + frame.width / 4, frame.center.dy),
              Offset(frame.width / 2 + 100, 0),
            ); // Clamped at the image boundary.
            await tester.pumpAndSettle();
          }
          if (scenario == 'reset') {
            await tester.tap(find.text('Reset'));
            await tester.pumpAndSettle();
          }
        }
        await tester.tap(find.text('Use crop'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(result, isNotNull);
        await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(result!);
          final image = (await codec.getNextFrame()).image;
          codec.dispose();
          expect(
            image.width,
            scenario == 'reset'
                ? 400
                : scenario == 'corner'
                ? 300
                : 200,
          );
          expect(
            image.height,
            scenario == 'rotate'
                ? 400
                : scenario == 'corner'
                ? 100
                : 200,
          );
          if (scenario == 'move' || scenario == 'resize') {
            final pixels = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final center =
                ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
            final expected = scenario == 'move' ? Colors.blue : Colors.red;
            expect(pixels!.getUint8(center), (expected.r * 255).round());
            expect(pixels.getUint8(center + 2), (expected.b * 255).round());
          }
          image.dispose();
        });
      } finally {
        semantics.dispose();
      }
    });
  }
}
