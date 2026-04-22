import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/gym.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  int selId = 3;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final plan = state.gym;
    final day = plan.days.firstWhere((x) => x.id == selId, orElse: () => plan.days.first);
    final pct = day.exercises.isEmpty
        ? 0.0
        : day.exercises.where((e) => e.done).length / day.exercises.length;
    final weekDone = plan.days.where((x) => x.done).length;
    final activeDays = plan.days.where((x) => x.exercises.isNotEmpty || x.label != 'Rest').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(theme: theme, greeting: Greeting(sub: plan.name, title: 'Workout'),
            right: [HeaderBtn(theme: theme, icon: LucideIcons.trendingUp)]),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 14, child: Column(children: [
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This week', style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('$weekDone of $activeDays sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
                ],
              )),
              Ring(
                pct: weekDone / 5, size: 42, stroke: 4,
                color: theme.accent, track: theme.surface2,
                child: Text('$weekDone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.ink)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              for (final d in plan.days) Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DayPill(day: d, selected: d.id == selId, theme: theme, onTap: () => setState(() => selId = d.id)),
              )),
            ]),
          ])),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.today ? 'Today' : 'Session', style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(day.label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.5)),
                ],
              ),
              if (day.exercises.isNotEmpty) Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.accent, letterSpacing: -0.5)),
                  Text('COMPLETE', style: TextStyle(fontSize: 10, color: theme.muted, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (day.exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(theme: theme, pad: 30, child: Column(children: [
              const Text('🌿', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text('Rest day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
              const SizedBox(height: 4),
              Text('Recovery matters. Stretch & sleep well.', style: TextStyle(fontSize: 13, color: theme.muted)),
            ])),
          )
        else
          for (var i = 0; i < day.exercises.length; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _ExerciseRow(
                ex: day.exercises[i],
                onToggle: () => state.toggleExercise(day.id, i),
                theme: theme,
              ),
            ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(theme: theme, title: 'Body weight', action: 'Log'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 16, child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text('78.2', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.6)),
                  const SizedBox(width: 4),
                  Text('kg', style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
                ]),
                Row(children: [
                  Icon(LucideIcons.trendingDown, color: theme.success, size: 12),
                  const SizedBox(width: 4),
                  Text('3.9 kg · 10 wk', style: TextStyle(color: theme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 80, child: _WeightChart(theme: theme)),
          ])),
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  final GymDay day;
  final bool selected;
  final AppTheme theme;
  final VoidCallback onTap;
  const _DayPill({required this.day, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rest = day.label == 'Rest';
    final bg = selected
        ? theme.accent
        : (day.done ? theme.accent.withOpacity(0.13) : theme.surface2);
    final fg = selected ? Colors.white : (day.done ? theme.accent : theme.ink);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: day.today && !selected ? Border.all(color: theme.accent, width: 1.5) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Opacity(opacity: 0.75, child: Text(day.short, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg))),
          const SizedBox(height: 4),
          Text(
            rest ? '—' : (day.done ? '✓' : (day.today ? 'NOW' : '')),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg),
          ),
        ]),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise ex;
  final VoidCallback onToggle;
  final AppTheme theme;
  const _ExerciseRow({required this.ex, required this.onToggle, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: ex.done ? 0.55 : 1,
      child: AppCard(theme: theme, pad: 14, child: Row(children: [
        CheckBubble(checked: ex.done, onTap: onToggle, theme: theme),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ex.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.2, decoration: ex.done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 3),
            Text('${ex.sets} sets × ${ex.reps}', style: TextStyle(fontSize: 12, color: theme.muted, fontFamily: 'JetBrainsMono')),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(10)),
          child: Text(ex.weight, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.ink, fontFamily: 'JetBrainsMono')),
        ),
      ])),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final AppTheme theme;
  const _WeightChart({required this.theme});

  static const data = [82.1, 81.4, 80.8, 80.5, 79.9, 79.2, 78.5, 78.2];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      return CustomPaint(
        size: Size(box.maxWidth, box.maxHeight),
        painter: _ChartPainter(color: theme.accent),
      );
    });
  }
}

class _ChartPainter extends CustomPainter {
  final Color color;
  _ChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const data = _WeightChart.data;
    const pad = 6.0;
    final minV = data.reduce((a, b) => a < b ? a : b) - 0.3;
    final maxV = data.reduce((a, b) => a > b ? a : b) + 0.3;
    final pts = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = pad + (i / (data.length - 1)) * (size.width - pad * 2);
      final y = pad + (1 - (data[i] - minV) / (maxV - minV)) * (size.height - pad * 2);
      pts.add(Offset(x, y));
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }

    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(area, areaPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(pts.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.color != color;
}
