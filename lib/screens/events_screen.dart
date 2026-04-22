import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/event.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/app_icons.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int? openId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final events = state.events;
    if (events.isEmpty) return const SizedBox.shrink();
    openId ??= events.first.id;
    final ev = events.firstWhere((e) => e.id == openId, orElse: () => events.first);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(theme: theme, greeting: const Greeting(sub: 'Planning ahead', title: 'Events'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.calendar)]),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final e = events[i];
              final active = e.id == openId;
              final p = e.items.isEmpty ? 0.0 : e.doneCount / e.items.length;
              return GestureDetector(
                onTap: () => setState(() => openId = e.id),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: active ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [e.color, e.color.withOpacity(0.8)]) : null,
                    color: active ? null : theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: active ? null : Border.all(color: theme.rule, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: active ? Colors.white.withOpacity(0.2) : e.color.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(AppIcons.byKey(e.icon), color: active ? Colors.white : e.color, size: 18),
                          ),
                          Text('${e.daysAway}d', style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5,
                            color: active ? Colors.white : theme.ink,
                          )),
                        ],
                      ),
                      const Spacer(),
                      Text(e.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: active ? Colors.white : theme.ink)),
                      const SizedBox(height: 2),
                      Text(e.date, style: TextStyle(fontSize: 11, color: active ? Colors.white.withOpacity(0.8) : theme.muted)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 3,
                          child: Stack(children: [
                            Container(color: active ? Colors.white.withOpacity(0.3) : theme.surface2),
                            FractionallySizedBox(
                              widthFactor: p,
                              child: Container(color: active ? Colors.white : e.color),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: AppCard(theme: theme, pad: 14, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('BUDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text('₹${_fmt(ev.totalEst)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.4)),
              ],
            ))),
            const SizedBox(width: 10),
            Expanded(child: AppCard(
              theme: theme, pad: 14,
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.accent.withOpacity(0.25), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SPENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.accent, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('₹${_fmt(ev.totalActual)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.accent, letterSpacing: -0.4)),
                ],
              ),
            )),
          ]),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(theme: theme, title: 'Checklist', action: '${ev.doneCount}/${ev.items.length}'),
        ),
        const SizedBox(height: 12),
        for (final it in ev.items) Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _EventItemRow(it: it, event: ev),
        ),
      ],
    );
  }
}

class _EventItemRow extends StatelessWidget {
  final EventItem it;
  final PlannedEvent event;
  const _EventItemRow({required this.it, required this.event});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = state.theme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: it.done ? 0.55 : 1,
      child: AppCard(theme: theme, pad: 14, child: Row(children: [
        CheckBubble(checked: it.done, onTap: () => state.toggleEventItem(event.id, it.id), theme: theme),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(it.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.1, decoration: it.done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'est ₹${_fmt(it.est)}', style: TextStyle(fontSize: 11, color: theme.muted, fontFamily: 'JetBrainsMono')),
              if (it.actual > 0) TextSpan(text: ' · spent ₹${_fmt(it.actual)}', style: TextStyle(fontSize: 11, color: theme.accent, fontFamily: 'JetBrainsMono')),
            ])),
          ],
        )),
      ])),
    );
  }
}

String _fmt(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}
