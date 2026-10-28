import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Flutter gestures keep the crop controls usable above a modal barrier on web.
/// The selection is normalized; exporting always uses the original image pixels.
class QuestionPhotoCrop extends StatefulWidget {
  final Uint8List bytes;

  const QuestionPhotoCrop({super.key, required this.bytes});

  @override
  State<QuestionPhotoCrop> createState() => _QuestionPhotoCropState();
}

class _QuestionPhotoCropState extends State<QuestionPhotoCrop> {
  ui.Image? _image;
  Rect _selection = const Rect.fromLTWH(0, 0, 1, 1);
  Rect? _dragSelection;
  Offset? _dragStart;
  int? _handle;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      ui.Image image;
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'This photo could not be opened. Try another photo.',
        );
      }
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _begin(Offset position, Rect frame) {
    final box = _inFrame(_selection, frame);
    final handles = _handles(box);
    var closest = 24.0;
    _handle = null;
    for (var i = 0; i < handles.length; i++) {
      final distance = (position - handles[i]).distance;
      if (distance <= closest) {
        closest = distance;
        _handle = i;
      }
    }
    if (_handle == null && !box.contains(position)) return;
    _dragStart = position;
    _dragSelection = _selection;
  }

  void _drag(Offset position, Rect frame) {
    final start = _dragStart;
    final original = _dragSelection;
    if (start == null || original == null) return;
    final delta = Offset(
      (position.dx - start.dx) / frame.width,
      (position.dy - start.dy) / frame.height,
    );
    Rect next;
    if (_handle == null) {
      next = original.shift(
        Offset(
          delta.dx.clamp(-original.left, 1 - original.right),
          delta.dy.clamp(-original.top, 1 - original.bottom),
        ),
      );
    } else {
      // Clockwise from top-left: corner, edge, corner, edge, ...
      final h = _handle!;
      final minWidth = math.min(original.width, 32 / frame.width);
      final minHeight = math.min(original.height, 32 / frame.height);
      var left = original.left;
      var top = original.top;
      var right = original.right;
      var bottom = original.bottom;
      if (h == 0 || h == 6 || h == 7) {
        left = (left + delta.dx).clamp(0, right - minWidth);
      }
      if (h <= 2) top = (top + delta.dy).clamp(0, bottom - minHeight);
      if (h >= 2 && h <= 4) {
        right = (right + delta.dx).clamp(left + minWidth, 1);
      }
      if (h >= 4 && h <= 6) {
        bottom = (bottom + delta.dy).clamp(top + minHeight, 1);
      }
      next = Rect.fromLTRB(left, top, right, bottom);
    }
    setState(() => _selection = next);
  }

  void _end() {
    _dragStart = null;
    _dragSelection = null;
    _handle = null;
  }

  Future<void> _rotate() async {
    final image = _image!;
    setState(() => _working = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..translate(image.height.toDouble(), 0)
        ..rotate(math.pi / 2);
      canvas.drawImage(image, Offset.zero, Paint());
      final picture = recorder.endRecording();
      final rotated = await picture.toImage(image.height, image.width);
      picture.dispose();
      if (!mounted) {
        rotated.dispose();
        return;
      }
      setState(() {
        _image = rotated;
        _selection = const Rect.fromLTWH(0, 0, 1, 1);
      });
      image.dispose();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not rotate the photo. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final image = _image!;
      final left = (_selection.left * image.width).floor();
      final top = (_selection.top * image.height).floor();
      final right = (_selection.right * image.width).ceil().clamp(
        left + 1,
        image.width,
      );
      final bottom = (_selection.bottom * image.height).ceil().clamp(
        top + 1,
        image.height,
      );
      final width = right - left;
      final height = bottom - top;
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        image,
        Rect.fromLTWH(
          left.toDouble(),
          top.toDouble(),
          width.toDouble(),
          height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint(),
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(width, height);
      picture.dispose();
      ByteData? data;
      try {
        data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        cropped.dispose();
      }
      if (data == null) throw StateError('No crop data');
      if (mounted) {
        Navigator.pop(
          context,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not crop the photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Crop your question'),
            actions: [
              TextButton(
                onPressed: _working ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Drag a corner or edge to resize. Drag inside to move. Keep all symbols and labels.',
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final image = _image;
                if (image == null) {
                  return Center(
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : Text(_error!),
                  );
                }
                final size = constraints.biggest;
                final scale = math.min(
                  math.max(1, size.width - 48) / image.width,
                  math.max(1, size.height - 48) / image.height,
                );
                final frame = Rect.fromCenter(
                  center: size.center(Offset.zero),
                  width: image.width * scale,
                  height: image.height * scale,
                );
                return GestureDetector(
                  key: const ValueKey('question-crop-surface'),
                  behavior: HitTestBehavior.opaque,
                  onPanDown: _working
                      ? null
                      : (event) => _begin(event.localPosition, frame),
                  onPanUpdate: _working
                      ? null
                      : (event) => _drag(event.localPosition, frame),
                  onPanEnd: (_) => _end(),
                  onPanCancel: _end,
                  child: CustomPaint(
                    size: size,
                    painter: _CropPainter(
                      image,
                      frame,
                      _inFrame(_selection, frame),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_error != null && _image != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: _working || _image == null
                      ? null
                      : () => setState(() {
                          _selection = const Rect.fromLTWH(0, 0, 1, 1);
                        }),
                  child: const Text('Reset'),
                ),
                TextButton.icon(
                  onPressed: _working || _image == null ? null : _rotate,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Rotate'),
                ),
                FilledButton(
                  onPressed: _working || _image == null ? null : _save,
                  child: Text(_working ? 'Processing…' : 'Use crop'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Rect _inFrame(Rect selection, Rect frame) => Rect.fromLTRB(
  frame.left + selection.left * frame.width,
  frame.top + selection.top * frame.height,
  frame.left + selection.right * frame.width,
  frame.top + selection.bottom * frame.height,
);

List<Offset> _handles(Rect rect) => [
  rect.topLeft,
  rect.topCenter,
  rect.topRight,
  rect.centerRight,
  rect.bottomRight,
  rect.bottomCenter,
  rect.bottomLeft,
  rect.centerLeft,
];

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect frame;
  final Rect selection;
  _CropPainter(this.image, this.frame, this.selection);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xff222222), BlendMode.src);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      frame,
      Paint()..filterQuality = FilterQuality.high,
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(selection);
    canvas.drawPath(mask, Paint()..color = const Color(0x99000000));
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(selection, line);
    for (var i = 1; i <= 2; i++) {
      final x = selection.left + selection.width * i / 3;
      final y = selection.top + selection.height * i / 3;
      canvas.drawLine(
        Offset(x, selection.top),
        Offset(x, selection.bottom),
        Paint()..color = const Color(0x88ffffff),
      );
      canvas.drawLine(
        Offset(selection.left, y),
        Offset(selection.right, y),
        Paint()..color = const Color(0x88ffffff),
      );
    }
    for (final point in _handles(selection)) {
      canvas.drawCircle(point, 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        9,
        Paint()
          ..color = const Color(0xffbc350d)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.image != image || old.frame != frame || old.selection != selection;
}
