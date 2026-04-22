import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/primitives.dart';
import '../widgets/app_icons.dart';

class AddSheet extends StatelessWidget {
  final VoidCallback onClose;
  const AddSheet({super.key, required this.onClose});

  static const options = [
    _Opt('tasks', 'Task', 'checkCircle', Color(0xFF8B7CFF)),
    _Opt('finance', 'Debt', 'wallet', Color(0xFF34D399)),
    _Opt('events', 'Event', 'calendar', Color(0xFFFB7185)),
    _Opt('gym', 'Workout', 'dumbbell', Color(0xFFF472B6)),
    _Opt('snapshots', 'Snapshot', 'camera', Color(0xFFFBBF24)),
    _Opt('more', 'Note', 'note', Color(0xFFA78BFA)),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.rule, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 18),
          Text('Quick add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 4),
          Text('What are you logging?', style: TextStyle(fontSize: 13, color: theme.muted)),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              for (final o in options) _OptButton(option: o, onTap: () {
                state.setScreen(o.key);
                onClose();
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _Opt {
  final String key, label, icon;
  final Color color;
  const _Opt(this.key, this.label, this.icon, this.color);
}

class _OptButton extends StatelessWidget {
  final _Opt option;
  final VoidCallback onTap;
  const _OptButton({required this.option, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.rule, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconChip(bg: option.color.withOpacity(0.13), size: 36, child: Icon(AppIcons.byKey(option.icon), color: option.color, size: 18)),
              const SizedBox(height: 10),
              Text(option.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
