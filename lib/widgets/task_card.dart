import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'primitives.dart';
import 'app_icons.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskItem task;
  final AppTheme theme;
  final VoidCallback onToggle;
  final Widget? trailing;
  const TaskCardWidget({super.key, required this.task, required this.theme, required this.onToggle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: task.done ? 0.55 : 1.0,
      child: AppCard(
        theme: theme,
        pad: 14,
        child: Row(children: [
          IconChip(
            bg: task.color.withOpacity(0.13),
            child: Icon(AppIcons.byKey(task.icon), color: task.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(task.title, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.2,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                )),
                const SizedBox(height: 3),
                Row(children: [
                  if (task.allDay) ...[
                    Icon(LucideIcons.repeat, size: 11, color: theme.accent),
                    const SizedBox(width: 3),
                    Text('Daily', style: TextStyle(fontSize: 12, color: theme.accent, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                  ],
                  Icon(LucideIcons.clock, size: 11, color: theme.muted),
                  const SizedBox(width: 3),
                  Text(task.time, style: TextStyle(fontSize: 12, color: theme.muted)),
                  if (task.streak >= 7) ...[
                    const SizedBox(width: 8),
                    Icon(LucideIcons.flame, size: 11, color: theme.accent),
                    const SizedBox(width: 3),
                    Text('${task.streak}', style: TextStyle(fontSize: 12, color: theme.accent, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CheckBubble(checked: task.done, onTap: onToggle, theme: theme),
          if (trailing != null) ...[const SizedBox(width: 2), trailing!],
        ]),
      ),
    );
  }
}
