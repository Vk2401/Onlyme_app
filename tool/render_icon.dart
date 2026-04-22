// Headless icon renderer — runs via `flutter test tool/render_icon.dart`.
// Paints the Only Me app icon at 1024x1024 and writes
// assets/icon/app_icon.png (full-bleed) + assets/icon/app_icon_fg.png
// (foreground glyph for Android adaptive icons, 432 safe-zone / 1024 canvas).

import 'dart:io';
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

// ── Full-bleed icon: gradient rounded square + foreground glyph ────────────

class _FullIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Solid gradient background. iOS masks to its own corner radius, Android
    // adaptive icon uses the separate foreground file — so we can paint edge
    // to edge here.
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF5EEAD4), // mint
          Color(0xFF2DD4BF),
          Color(0xFF7C3AED), // violet accent2
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Soft highlight glow, top-left.
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.2),
      size.width * 0.55,
      Paint()..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.25, size.height * 0.2),
        radius: size.width * 0.55,
      )),
    );

    _paintGlyph(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Only the glyph + subtle shadow, no background (for Android adaptive fg).
class _ForegroundOnlyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _paintGlyph(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stylised "M" made from two thick rounded strokes, with a small checkmark
/// badge at the bottom-right — conveys "Me" + "tracker/checklist".
void _paintGlyph(Canvas canvas, Size size) {
  final w = size.width;
  final h = size.height;
  final cx = w / 2;
  final cy = h / 2;

  // Soft drop shadow pass — render the same path in low-alpha black offset.
  void drawM(Paint paint) {
    final strokeW = w * 0.14;

    // Outer bounds of the M
    final top = cy - w * 0.19;
    final bot = cy + w * 0.19;
    final left = cx - w * 0.23;
    final right = cx + w * 0.23;
    final midX = cx;
    final dipY = cy + w * 0.02;

    final p = Path()
      ..moveTo(left, bot)
      ..lineTo(left, top)
      ..lineTo(midX, dipY)
      ..lineTo(right, top)
      ..lineTo(right, bot);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = paint.color
      ..maskFilter = paint.maskFilter;
    canvas.drawPath(p, stroke);
  }

  // Shadow
  canvas.save();
  canvas.translate(0, h * 0.012);
  drawM(Paint()
    ..color = Colors.black.withOpacity(0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
  canvas.restore();

  // Main M — white with a tiny tint so it reads as soft, not stark
  drawM(Paint()..color = const Color(0xFFFDFDFD));

  // Checkmark badge in the bottom-right
  final badgeCenter = Offset(cx + w * 0.20, cy + w * 0.23);
  final badgeRadius = w * 0.11;

  // Badge shadow
  canvas.drawCircle(
    badgeCenter.translate(0, h * 0.01),
    badgeRadius,
    Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
  );

  // Badge fill
  canvas.drawCircle(
    badgeCenter,
    badgeRadius,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFF0F172A), Color(0xFF1F2937)],
      ).createShader(Rect.fromCircle(center: badgeCenter, radius: badgeRadius)),
  );

  // Check tick inside badge
  final tick = Path()
    ..moveTo(badgeCenter.dx - badgeRadius * 0.42, badgeCenter.dy + badgeRadius * 0.02)
    ..lineTo(badgeCenter.dx - badgeRadius * 0.08, badgeCenter.dy + badgeRadius * 0.38)
    ..lineTo(badgeCenter.dx + badgeRadius * 0.48, badgeCenter.dy - badgeRadius * 0.30);
  canvas.drawPath(
    tick,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.022
      ..color = const Color(0xFF5EEAD4),
  );
}
