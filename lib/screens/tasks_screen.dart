import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/task_card.dart';
import '../widgets/segmented.dart';
import '../widgets/app_icons.dart';
import '../widgets/confirm_sheet.dart';

const _iconKeys = [
  'check', 'checkCircle', 'droplet', 'dumbbell', 'heart', 'note',
  'wallet', 'calendar', 'flame', 'bell', 'utensils', 'gift',
  'sparkle', 'camera', 'user', 'clock', 'link', 'home',
];

const _colorPalette = [
  Color(0xFF8B7CFF), Color(0xFFFF8A6B), Color(0xFF5EEAD4), Color(0xFFFBBF24),
  Color(0xFF60A5FA), Color(0xFFF472B6), Color(0xFFEF4444), Color(0xFF22C55E),
  Color(0xFFA78BFA), Color(0xFF34D399), Color(0xFFFB7185), Color(0xFF22D3EE),
];

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
          greeting: const Greeting(sub: 'My tasks', title: 'Tasks'),
          right: [
            HeaderBtn(
              theme: theme,
              icon: LucideIcons.plus,
              onTap: () => _openTaskSheet(context),
            ),
          ],
        ),

        // Progress card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            theme: theme, pad: 18,
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's completion", style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${done.length} / ${tasks.length} tasks',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.6)),
                  ],
                )),
                Ring(
                  pct: pct, size: 54, stroke: 5,
                  color: theme.accent, track: theme.surface2,
                  child: Text('${(pct * 100).round()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.ink)),
                ),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(height: 6, child: Stack(children: [
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
                ])),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Segmented<String>(
            theme: theme, value: tab,
            onChanged: (v) => setState(() => tab = v),
            items: const [
              MapEntry('today', 'Today'),
              MapEntry('upcoming', 'Upcoming'),
              MapEntry('all', 'All'),
            ],
          ),
        ),

        if (tasks.isEmpty) ...[
          const SizedBox(height: 40),
          _EmptyState(theme: theme, onAdd: () => _openTaskSheet(context)),
        ] else ...[
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionTag(label: 'Pending', count: pending.length, theme: theme),
            ),
            const SizedBox(height: 12),
            for (final t in pending)
              _DismissibleTask(
                task: t, theme: theme,
                onToggle: () => state.toggleTask(t.id),
                onEdit: () => _openTaskSheet(context, task: t),
                onDelete: () => state.deleteTask(t.id),
              ),
          ],
          if (done.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionTag(label: 'Completed', count: done.length, theme: theme),
            ),
            const SizedBox(height: 12),
            for (final t in done)
              _DismissibleTask(
                task: t, theme: theme,
                onToggle: () => state.toggleTask(t.id),
                onEdit: () => _openTaskSheet(context, task: t),
                onDelete: () => state.deleteTask(t.id),
              ),
          ],
        ],
      ],
    );
  }

  Future<void> _openTaskSheet(BuildContext context, {TaskItem? task}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _TaskSheet(task: task),
    );
  }
}

// ── Dismissible wrapper ──────────────────────────────────────────────────────

class _DismissibleTask extends StatelessWidget {
  final TaskItem task;
  final AppTheme theme;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DismissibleTask({
    required this.task, required this.theme,
    required this.onToggle, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.fromLTRB(0, 0, 28, 0),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
          color: theme.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'Delete task?',
        message: task.title,
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: TaskCardWidget(task: task, theme: theme, onToggle: onToggle),
        ),
      ),
    );
  }
}

// ── Add / Edit sheet ──────────────────────────────────────────────────────────

class _TaskSheet extends StatefulWidget {
  final TaskItem? task;
  const _TaskSheet({this.task});

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final TextEditingController _title;
  late final TextEditingController _time;
  late final TextEditingController _cat;
  late String _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _time = TextEditingController(text: t?.time ?? '');
    _cat = TextEditingController(text: t?.cat ?? '');
    _icon = t?.icon ?? 'checkCircle';
    _color = t?.color ?? _colorPalette[0];
  }

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _cat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = state.theme;
    final editing = widget.task != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.rule, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DragHandle(theme: theme),
            const SizedBox(height: 18),
            Text(editing ? 'Edit task' : 'New task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
            const SizedBox(height: 18),

            // Title
            _Field(theme: theme, hint: 'Task name', controller: _title, autofocus: !editing),
            const SizedBox(height: 10),

            // Time + Category row
            Row(children: [
              Expanded(child: _Field(theme: theme, hint: 'Time (e.g. 07:30)', controller: _time)),
              const SizedBox(width: 10),
              Expanded(child: _Field(theme: theme, hint: 'Category', controller: _cat)),
            ]),
            const SizedBox(height: 16),

            // Icon picker
            Text('Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _iconKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final key = _iconKeys[i];
                  final selected = _icon == key;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: selected ? theme.accent : theme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? theme.accent : theme.rule, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(AppIcons.byKey(key), size: 20,
                          color: selected ? Colors.white : theme.ink2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final c in _colorPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _color == c
                          ? Border.all(color: theme.ink, width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 22),

            // Submit
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
                ),
                alignment: Alignment.center,
                child: Text(editing ? 'Save changes' : 'Add task',
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    if (widget.task != null) {
      state.editTask(widget.task!.copyWith(
        title: _title.text.trim(),
        time: _time.text.trim(),
        cat: _cat.text.trim(),
        icon: _icon,
        color: _color,
      ));
    } else {
      state.addTask(
        title: _title.text.trim(),
        time: _time.text.trim().isEmpty ? 'all day' : _time.text.trim(),
        cat: _cat.text.trim().isEmpty ? 'Personal' : _cat.text.trim(),
        icon: _icon,
        color: _color,
      );
    }
    Navigator.of(context).pop();
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final AppTheme theme;
  const _DragHandle({required this.theme});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

class _Field extends StatelessWidget {
  final AppTheme theme;
  final String hint;
  final TextEditingController controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  const _Field({required this.theme, required this.hint, required this.controller, this.autofocus = false, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: theme.muted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onAdd;
  const _EmptyState({required this.theme, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        theme: theme, pad: 32,
        child: Column(children: [
          Icon(LucideIcons.checkSquare, size: 40, color: theme.muted),
          const SizedBox(height: 12),
          Text('No tasks yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
          const SizedBox(height: 6),
          Text('Tap + to add your first task', style: TextStyle(fontSize: 13, color: theme.muted)),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
              child: const Text('Add task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ]),
      ),
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
        decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.rule, width: 1)),
        child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.ink)),
      ),
    ]);
  }
}
