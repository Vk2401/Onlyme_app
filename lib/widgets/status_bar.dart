import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhoneStatusBar extends StatelessWidget {
  final AppTheme theme;
  final String time;
  const PhoneStatusBar({super.key, required this.theme, this.time = '8:24'});

  @override
  Widget build(BuildContext context) {
    final c = theme.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(time, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: c,
          fontFamily: 'SF Pro Text',
        )),
        Row(children: [
          _Signal(color: c), const SizedBox(width: 5),
          _Wifi(color: c), const SizedBox(width: 5),
          _Battery(color: c),
        ]),
      ]),
    );
  }
}

class _Signal extends StatelessWidget {
  final Color color;
  const _Signal({required this.color});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(17, 11), painter: _SignalPainter(color));
  }
}

class _SignalPainter extends CustomPainter {
  final Color color;
  _SignalPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const bars = [4.0, 6.0, 8.5, 11.0];
    for (var i = 0; i < bars.length; i++) {
      final h = bars[i];
      final x = i * 4.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, 3, h), const Radius.circular(0.5)),
        p,
      );
    }
  }
  @override
  bool shouldRepaint(covariant _SignalPainter old) => old.color != color;
}

class _Wifi extends StatelessWidget {
  final Color color;
  const _Wifi({required this.color});
  @override
  Widget build(BuildContext context) => Icon(Icons.wifi_rounded, size: 14, color: color);
}

class _Battery extends StatelessWidget {
  final Color color;
  const _Battery({required this.color});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(25, 11), painter: _BatteryPainter(color));
  }
}

class _BatteryPainter extends CustomPainter {
  final Color color;
  _BatteryPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, 21, 10),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rect, stroke);
    final fill = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, 16, 7), const Radius.circular(1.5)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(22, 3.5, 1.5, 4), const Radius.circular(1)),
      fill..color = color.withOpacity(0.4),
    );
  }
  @override
  bool shouldRepaint(covariant _BatteryPainter old) => old.color != color;
}
