// Headless icon renderer — runs via `flutter test tool/render_icon.dart`.
// Paints the Only Me cartoon mascot at 1024x1024 and writes two PNGs:
//   * assets/icon/app_icon.png        — full-bleed (mint→blue gradient bg + mascot)
//   * assets/icon/app_icon_fg.png     — transparent foreground (mascot only) for
//                                       the Android adaptive icon.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render app icons', (tester) async {
    await tester.runAsync(() async {
      await _writePng(
        path: 'assets/icon/app_icon.png',
        size: 1024,
        painter: _FullIconPainter(),
      );
      await _writePng(
        path: 'assets/icon/app_icon_fg.png',
        size: 1024,
        painter: _ForegroundOnlyPainter(),
        transparent: true,
      );
    });
  });
}

Future<void> _writePng({
  required String path,
  required int size,
  required CustomPainter painter,
  bool transparent = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  if (!transparent) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = const Color(0xFF0B0B10),
    );
  }
  painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
}

// ── Full-bleed icon: gradient + mascot ─────────────────────────────────────

class _FullIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Friendly mint → sky gradient. Less busy than a 3-stop rainbow so the
    // mascot reads clearly.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EE7C8), Color(0xFF3DC4F2)],
        ).createShader(rect),
    );

    // Soft top-left highlight for subtle depth.
    final hlCenter = Offset(size.width * 0.25, size.height * 0.22);
    canvas.drawCircle(
      hlCenter,
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.32), Colors.white.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: hlCenter, radius: size.width * 0.55)),
    );

    // Decorative sparkles in the corners (playful feel, low contrast).
    _drawSparkle(canvas, Offset(size.width * 0.82, size.height * 0.18), size.width * 0.055, Colors.white.withOpacity(0.85));
    _drawSparkle(canvas, Offset(size.width * 0.16, size.height * 0.80), size.width * 0.040, Colors.white.withOpacity(0.75));
    _drawSparkle(canvas, Offset(size.width * 0.88, size.height * 0.62), size.width * 0.028, Colors.white.withOpacity(0.65));

    _paintMascot(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ForegroundOnlyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _paintMascot(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mascot ──────────────────────────────────────────────────────────────────

/// A cute rounded-square face: cream body, big kawaii eyes with highlights,
/// pink cheek blush, and a small smile. Sits roughly centre of the canvas,
/// scaled so Android adaptive-icon masking (~20% inset) keeps the whole face
/// visible.
void _paintMascot(Canvas canvas, Size size) {
  final w = size.width;
  final h = size.height;
  final cx = w / 2;
  final cy = h / 2 + h * 0.01; // ever so slightly below centre feels nicer

  final faceSize = w * 0.58;
  final faceRect = Rect.fromCenter(center: Offset(cx, cy), width: faceSize, height: faceSize);
  final faceRRect = RRect.fromRectAndRadius(faceRect, Radius.circular(w * 0.15));

  // Drop shadow under the face.
  canvas.drawRRect(
    faceRRect.shift(Offset(0, h * 0.015)),
    Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
  );

  // Base cream fill with a subtle vertical gradient for depth.
  canvas.drawRRect(
    faceRRect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFF6E2), Color(0xFFFFE3B8)],
      ).createShader(faceRect),
  );

  // Subtle warm rim highlight along the top.
  canvas.drawRRect(
    faceRRect.deflate(w * 0.012),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.007
      ..color = Colors.white.withOpacity(0.55),
  );

  // Cheek blush — two soft pink circles.
  final blushPaint = Paint()
    ..color = const Color(0xFFFF9AA8).withOpacity(0.55)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  final cheekY = cy + faceSize * 0.14;
  canvas.drawCircle(Offset(cx - faceSize * 0.26, cheekY), faceSize * 0.10, blushPaint);
  canvas.drawCircle(Offset(cx + faceSize * 0.26, cheekY), faceSize * 0.10, blushPaint);

  // Eyes — big black rounded ovals, slightly squished for kawaii.
  final eyeY = cy - faceSize * 0.08;
  final eyeDx = faceSize * 0.19;
  final eyeW = faceSize * 0.13;
  final eyeH = faceSize * 0.18;

  void drawEye(double offsetX) {
    final eyeRect = Rect.fromCenter(
      center: Offset(cx + offsetX, eyeY),
      width: eyeW,
      height: eyeH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(eyeRect, Radius.circular(eyeW)),
      Paint()..color = const Color(0xFF14141E),
    );
    // Small white highlight
    canvas.drawCircle(
      Offset(eyeRect.center.dx + eyeW * 0.18, eyeRect.center.dy - eyeH * 0.22),
      eyeW * 0.22,
      Paint()..color = Colors.white,
    );
    // Tiny secondary highlight
    canvas.drawCircle(
      Offset(eyeRect.center.dx - eyeW * 0.12, eyeRect.center.dy + eyeH * 0.18),
      eyeW * 0.09,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }

  drawEye(-eyeDx);
  drawEye(eyeDx);

  // Smile — a small upward curve.
  final mouthY = cy + faceSize * 0.22;
  final mouthW = faceSize * 0.22;
  final mouthPath = Path()
    ..moveTo(cx - mouthW / 2, mouthY)
    ..quadraticBezierTo(cx, mouthY + faceSize * 0.09, cx + mouthW / 2, mouthY);

  canvas.drawPath(
    mouthPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.022
      ..color = const Color(0xFF14141E),
  );

  // Heart antenna / accessory on top — tiny heart over the forehead, gives
  // the mascot a distinct "personal tracker" hook (you, cared for).
  _drawHeart(
    canvas: canvas,
    center: Offset(cx, cy - faceSize * 0.58),
    size: faceSize * 0.12,
    color: const Color(0xFFFF6B8B),
  );
}

void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
  final p = Path();
  const points = 4;
  for (var i = 0; i < points * 2; i++) {
    final angle = (i * 3.14159 / points) - 3.14159 / 2;
    final r = i.isEven ? radius : radius * 0.35;
    final x = center.dx + r * _cos(angle);
    final y = center.dy + r * _sin(angle);
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  p.close();
  canvas.drawPath(p, Paint()..color = color);
}

void _drawHeart({required Canvas canvas, required Offset center, required double size, required Color color}) {
  final w = size;
  final h = size;
  final path = Path();
  path.moveTo(center.dx, center.dy + h * 0.35);
  path.cubicTo(
    center.dx + w * 0.6, center.dy,
    center.dx + w * 0.6, center.dy - h * 0.55,
    center.dx, center.dy - h * 0.15,
  );
  path.cubicTo(
    center.dx - w * 0.6, center.dy - h * 0.55,
    center.dx - w * 0.6, center.dy,
    center.dx, center.dy + h * 0.35,
  );
  path.close();

  // Shadow
  canvas.drawPath(
    path.shift(Offset(0, size * 0.08)),
    Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.drawPath(path, Paint()..color = color);
  // Tiny highlight
  canvas.drawCircle(
    Offset(center.dx - w * 0.15, center.dy - h * 0.18),
    w * 0.09,
    Paint()..color = Colors.white.withOpacity(0.75),
  );
}

double _cos(double rad) => math.cos(rad);
double _sin(double rad) => math.sin(rad);
