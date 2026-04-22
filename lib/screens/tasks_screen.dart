import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/task_card.dart';
import '../widgets/segmented.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String tab = 'today';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final tasks = state.tasks;
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    final pct = tasks.isEmpty ? 0.0 : done.length / tasks.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Wednesday, Apr 21', title: 'My tasks'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.search)],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            theme: theme, pad: 18,
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s completion', style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${done.length} / ${tasks.length} tasks',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.6)),
                  ],
                )),
                Ring(
                  pct: pct, size: 54, stroke: 5,
                  color: theme.accent, track: theme.surface2,
                  child: Text('${(pct * 100).round()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.ink)),
                ),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Stack(children: [
                    Container(color: theme.surface2),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      widthFactor: pct,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [theme.accent, theme.accent2]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Segmented<String>(
            theme: theme,
            value: tab,
            onChanged: (v) => setState(() => tab = v),
            items: const [
              MapEntry('today', 'Today'),
              MapEntry('upcoming', 'Upcoming'),
              MapEntry('all', 'All'),
            ],
          ),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionTag(label: 'Pending', count: pending.length, theme: theme),
          ),
          const SizedBox(height: 12),
          for (final t in pending) Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TaskCardWidget(task: t, theme: theme, onToggle: () => state.toggleTask(t.id)),
          ),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionTag(label: 'Completed', count: done.length, theme: theme),
          ),
          const SizedBox(height: 12),
          for (final t in done) Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TaskCardWidget(task: t, theme: theme, onToggle: () => state.toggleTask(t.id)),
          ),
        ],
      ],
    );
  }
}

class _SectionTag extends StatelessWidget {
  final String label;
  final int count;
  final AppTheme theme;
  const _SectionTag({required this.label, required this.count, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.rule, width: 1),
        ),
        child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.ink)),
      ),
    ]);
  }
}
