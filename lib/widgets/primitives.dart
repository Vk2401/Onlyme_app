import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final AppTheme theme;
  final double pad;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;
  final EdgeInsets? margin;

  const AppCard({
    super.key,
    required this.child,
    required this.theme,
    this.pad = 16,
    this.onTap,
    this.decoration,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final deco = decoration ??
        BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.rule, width: 1),
        );

    final body = Container(
      padding: EdgeInsets.all(pad),
      decoration: deco,
      child: child,
    );

    if (onTap == null) {
      return Container(margin: margin, child: body);
    }
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: (deco.borderRadius as BorderRadius?),
        child: InkWell(
          onTap: onTap,
          borderRadius: (deco.borderRadius as BorderRadius?),
          child: body,
        ),
      ),
    );
  }
}

class IconChip extends StatelessWidget {
  final Widget child;
  final Color bg;
  final double size;
  const IconChip({super.key, required this.child, required this.bg, this.size = 40});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class Ring extends StatelessWidget {
  final double pct;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;
  const Ring({
    super.key,
    required this.pct,
    this.size = 46,
    this.stroke = 4,
    required this.color,
    required this.track,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(pct: v, stroke: stroke, color: color, track: track),
          ),
        ),
        if (child != null) child!,
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter({required this.pct, required this.stroke, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.width - stroke) / 2;
    final trackP = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, r, trackP);

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false, p);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.pct != pct || old.color != color || old.track != track || old.stroke != stroke;
}

class CheckBubble extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  final AppTheme theme;
  final double size;
  const CheckBubble({super.key, required this.checked, required this.onTap, required this.theme, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? theme.accent : Colors.transparent,
          border: Border.all(
            color: checked ? theme.accent : theme.rule,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: checked
              ? Icon(Icons.check, key: const ValueKey('v'), size: 14, color: theme.bg)
              : const SizedBox.shrink(key: ValueKey('x')),
        ),
      ),
    );
  }
}

class SectionHead extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets? padding;
  const SectionHead({super.key, required this.theme, required this.title, this.action, this.onAction, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.3)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.accent)),
          ),
      ]),
    );
  }
}
