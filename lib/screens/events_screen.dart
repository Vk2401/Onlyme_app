import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/app_icons.dart';
import '../widgets/confirm_sheet.dart';

const _eventIconKeys = [
  'gift', 'sparkle', 'calendar', 'heart', 'utensils', 'camera',
  'flame', 'dumbbell', 'note', 'link', 'user', 'home',
];

const _eventColors = [
  Color(0xFFFB7185), Color(0xFFFBBF24), Color(0xFF8B7CFF), Color(0xFF5EEAD4),
  Color(0xFF60A5FA), Color(0xFFF472B6), Color(0xFF34D399), Color(0xFFFF8A6B),
];

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
    final cur = state.profile.currencySymbol;
    final events = state.events;

    if (events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          AppHeader(
            theme: theme,
            greeting: const Greeting(sub: 'Planning ahead', title: 'Events'),
            right: [HeaderBtn(theme: theme, icon: LucideIcons.plus, onTap: () => _openEventSheet(context))],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 32,
              child: Column(children: [
                Icon(LucideIcons.calendar, size: 40, color: theme.muted),
                const SizedBox(height: 12),
                Text('No events yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
                const SizedBox(height: 6),
                Text('Tap + to plan your first event', style: TextStyle(fontSize: 13, color: theme.muted)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => _openEventSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Add event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    openId ??= events.first.id;
    final ev = events.firstWhere((e) => e.id == openId, orElse: () => events.first);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Planning ahead', title: 'Events'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.plus, onTap: () => _openEventSheet(context))],
        ),

        // Event carousel
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
                onLongPress: () => _showEventOptions(context, e),
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      child: SizedBox(height: 3, child: Stack(children: [
                        Container(color: active ? Colors.white.withOpacity(0.3) : theme.surface2),
                        FractionallySizedBox(widthFactor: p, child: Container(color: active ? Colors.white : e.color)),
                      ])),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // Budget cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: AppCard(theme: theme, pad: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('BUDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text('$cur${_fmt(ev.totalEst)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.4)),
            ]))),
            const SizedBox(width: 10),
            Expanded(child: AppCard(
              theme: theme, pad: 14,
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.accent.withOpacity(0.25), width: 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('SPENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.accent, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text('$cur${_fmt(ev.totalActual)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.accent, letterSpacing: -0.4)),
              ]),
            )),
          ]),
        ),

        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            theme: theme,
            title: 'Checklist',
            action: '+ Add item',
            onAction: () => _openAddItemSheet(context, ev.id),
          ),
        ),
        const SizedBox(height: 12),

        if (ev.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 20,
              child: Text('No checklist items yet. Tap "+ Add item" above.', style: TextStyle(fontSize: 13, color: theme.muted)),
            ),
          )
        else
          for (final it in ev.items)
            _DismissibleItem(it: it, event: ev, theme: theme),
      ],
    );
  }

  void _showEventOptions(BuildContext context, PlannedEvent e) {
    final theme = context.read<AppState>().theme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.rule),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          _OptionRow(icon: LucideIcons.pencil, label: 'Edit event', color: theme.ink, onTap: () {
            Navigator.pop(context);
            _openEventSheet(context, event: e);
          }),
          const SizedBox(height: 4),
          _OptionRow(icon: LucideIcons.trash2, label: 'Delete event', color: theme.danger, onTap: () async {
            Navigator.pop(context);
            final ok = await confirmDelete(
              context,
              title: 'Delete event?',
              message: '${e.title} · ${e.items.length} items',
            );
            if (!ok) return;
            if (!context.mounted) return;
            context.read<AppState>().deleteEvent(e.id);
            setState(() => openId = null);
          }),
        ]),
      ),
    );
  }

  Future<void> _openEventSheet(BuildContext context, {PlannedEvent? event}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _EventSheet(event: event),
    );
  }

  Future<void> _openAddItemSheet(BuildContext context, int eventId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _EventItemSheet(eventId: eventId),
    );
  }
}

// ── Dismissible checklist item ────────────────────────────────────────────────

class _DismissibleItem extends StatelessWidget {
  final EventItem it;
  final PlannedEvent event;
  final AppTheme theme;
  const _DismissibleItem({required this.it, required this.event, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(it.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.fromLTRB(0, 0, 28, 0),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(color: theme.danger, borderRadius: BorderRadius.circular(18)),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'Delete checklist item?',
        message: it.label,
      ),
      onDismissed: (_) => context.read<AppState>().deleteEventItem(event.id, it.id),
      child: GestureDetector(
        onLongPress: () => _openEditActualSheet(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _EventItemRow(it: it, event: event),
        ),
      ),
    );
  }

  void _openEditActualSheet(BuildContext context) {
    final state = context.read<AppState>();
    final theme = state.theme;
    final cur = state.profile.currencySymbol;
    final ctrl = TextEditingController(text: it.actual > 0 ? it.actual.toString() : '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: theme.rule),
          ),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text('Log actual spend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
            const SizedBox(height: 4),
            Text(it.label, style: TextStyle(fontSize: 13, color: theme.muted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Text(cur, style: TextStyle(fontSize: 22, color: theme.muted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.ink),
                  decoration: InputDecoration(border: InputBorder.none, isDense: true, hintText: '0', hintStyle: TextStyle(color: theme.muted)),
                )),
              ]),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                final val = int.tryParse(ctrl.text.trim()) ?? 0;
                context.read<AppState>().editEventItem(event.id, it.copyWith(actual: val));
                Navigator.of(ctx).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))]),
                alignment: Alignment.center,
                child: const Text('Save', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EventItemRow extends StatelessWidget {
  final EventItem it;
  final PlannedEvent event;
  const _EventItemRow({required this.it, required this.event});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final cur = state.profile.currencySymbol;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: it.done ? 0.55 : 1,
      child: AppCard(theme: theme, pad: 14, child: Row(children: [
        CheckBubble(checked: it.done, onTap: () => state.toggleEventItem(event.id, it.id), theme: theme),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(it.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.1, decoration: it.done ? TextDecoration.lineThrough : null)),
          const SizedBox(height: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'est $cur${_fmt(it.est)}', style: TextStyle(fontSize: 11, color: theme.muted)),
            if (it.actual > 0) TextSpan(text: ' · spent $cur${_fmt(it.actual)}', style: TextStyle(fontSize: 11, color: theme.accent)),
          ])),
        ])),
        Icon(LucideIcons.pencil, size: 14, color: theme.muted),
      ])),
    );
  }
}

// ── Add / Edit event sheet ────────────────────────────────────────────────────

class _EventSheet extends StatefulWidget {
  final PlannedEvent? event;
  const _EventSheet({this.event});

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  late final TextEditingController _title;
  late final TextEditingController _date;
  late final TextEditingController _days;
  late String _icon;
  late Color _color;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _date = TextEditingController(text: e?.date ?? '');
    _days = TextEditingController(text: e?.daysAway.toString() ?? '');
    _icon = e?.icon ?? 'gift';
    _color = e?.color ?? _eventColors[0];
    _scheduledAt = e?.scheduledAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    final editing = widget.event != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.rule, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text(editing ? 'Edit event' : 'New event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 18),

          _EField(theme: theme, hint: 'Event name', controller: _title, autofocus: !editing),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _EField(theme: theme, hint: 'Date (e.g. Nov 14)', controller: _date)),
            const SizedBox(width: 10),
            Expanded(child: _EField(theme: theme, hint: 'Days away', controller: _days, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 10),

          _EventReminderRow(
            theme: theme,
            value: _scheduledAt,
            onChange: (v) => setState(() {
              _scheduledAt = v;
              if (v != null) {
                final now = DateTime.now();
                final dd = DateTime(v.year, v.month, v.day).difference(DateTime(now.year, now.month, now.day)).inDays;
                _days.text = dd.toString();
                if (_date.text.trim().isEmpty) {
                  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                  _date.text = '${months[v.month - 1]} ${v.day}';
                }
              }
            }),
          ),
          const SizedBox(height: 16),

          Text('Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _eventIconKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final key = _eventIconKeys[i];
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
                    child: Icon(AppIcons.byKey(key), size: 20, color: selected ? Colors.white : theme.ink2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in _eventColors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: _color == c
                        ? Border.all(color: theme.ink, width: 2.5)
                        : Border.all(color: Colors.transparent, width: 2.5),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 22),

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
              child: Text(editing ? 'Save changes' : 'Add event',
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    final daysAway = int.tryParse(_days.text.trim()) ?? 0;
    if (widget.event != null) {
      state.editEvent(widget.event!.copyWith(
        title: _title.text.trim(),
        date: _date.text.trim().isEmpty ? '—' : _date.text.trim(),
        daysAway: daysAway,
        icon: _icon,
        color: _color,
        scheduledAt: _scheduledAt,
        clearScheduledAt: _scheduledAt == null,
      ));
    } else {
      state.addEvent(
        title: _title.text.trim(),
        date: _date.text.trim().isEmpty ? '—' : _date.text.trim(),
        daysAway: daysAway,
        icon: _icon,
        color: _color,
        scheduledAt: _scheduledAt,
      );
    }
    Navigator.of(context).pop();
  }
}

class _EventReminderRow extends StatelessWidget {
  final AppTheme theme;
  final DateTime? value;
  final ValueChanged<DateTime?> onChange;
  const _EventReminderRow({required this.theme, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'No reminder · optional'
        : _formatEventReminder(value!);
    return GestureDetector(
      onTap: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(LucideIcons.bell, size: 18, color: theme.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: value == null ? theme.muted : theme.ink,
              fontWeight: FontWeight.w500,
            ),
          )),
          if (value != null)
            GestureDetector(
              onTap: () => onChange(null),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(LucideIcons.x, size: 16, color: theme.muted),
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = value ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;
    onChange(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

String _formatEventReminder(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final m = d.minute.toString().padLeft(2, '0');
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final suffix = d.hour < 12 ? 'AM' : 'PM';
  return 'Remind: ${months[d.month - 1]} ${d.day} · $h12:$m $suffix';
}

// ── Add event item sheet ──────────────────────────────────────────────────────

class _EventItemSheet extends StatefulWidget {
  final int eventId;
  const _EventItemSheet({required this.eventId});

  @override
  State<_EventItemSheet> createState() => _EventItemSheetState();
}

class _EventItemSheetState extends State<_EventItemSheet> {
  final _label = TextEditingController();
  final _est = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _est.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = state.theme;
    final cur = state.profile.currencySymbol;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.rule),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text('Add checklist item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 18),
          _EField(theme: theme, hint: 'Item name (e.g. Hotel booking)', controller: _label, autofocus: true),
          const SizedBox(height: 10),
          _EField(theme: theme, hint: 'Estimated cost ($cur)', controller: _est, keyboardType: TextInputType.number),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () {
              if (_label.text.trim().isEmpty) return;
              context.read<AppState>().addEventItem(
                widget.eventId,
                label: _label.text.trim(),
                est: int.tryParse(_est.text.trim()) ?? 0,
              );
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: const Text('Add item', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Option row ────────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionRow({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _EField extends StatelessWidget {
  final AppTheme theme;
  final String hint;
  final TextEditingController controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  const _EField({required this.theme, required this.hint, required this.controller, this.autofocus = false, this.keyboardType});

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

String _fmt(int n) {
  if (n <= 0) return '0';
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
