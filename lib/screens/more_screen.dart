import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/debt.dart';
import '../services/notifications_service.dart';
import '../storage/export_io.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/app_icons.dart';
import '../widgets/confirm_sheet.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback onOpenTweaks;
  const MoreScreen({super.key, required this.onOpenTweaks});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final profile = state.profile;

    // --- Real data summaries ---
    final pendingTasks = state.tasks.where((t) => !t.done).length;
    final doneTasks = state.tasks.length - pendingTasks;
    final tasksSub = state.tasks.isEmpty
        ? 'No tasks yet'
        : '${state.tasks.length} total · $doneTasks done';

    final activeDebts = state.debts.where((d) => !d.settled).toList();
    final iOwe = activeDebts.where((d) => d.type == DebtType.iOwe).fold<int>(0, (s, d) => s + d.remain);
    final owedMe = activeDebts.where((d) => d.type == DebtType.theyOwe).fold<int>(0, (s, d) => s + d.remain);
    final cur = profile.currencySymbol;
    final financeSub = state.debts.isEmpty
        ? 'No debts tracked'
        : '${activeDebts.length} active · owe $cur${_fmtK(iOwe)} · owed $cur${_fmtK(owedMe)}';

    final upcomingEvents = state.events.where((e) => e.daysAway >= 0).toList();
    final eventsSub = state.events.isEmpty
        ? 'No events planned'
        : '${state.events.length} planned${upcomingEvents.isNotEmpty ? ' · next in ${upcomingEvents.first.daysAway}d' : ''}';

    final totalExercises = state.gym.days.fold<int>(0, (s, d) => s + d.exercises.length);
    final doneDays = state.gym.days.where((d) => d.done).length;
    final gymSub = totalExercises == 0
        ? '${state.gym.name} · no exercises yet'
        : '${state.gym.name} · $doneDays/${state.gym.days.length} days · $totalExercises exercises';

    final totalSnaps = state.snapshots.values.fold<int>(0, (s, l) => s + l.length);
    final snapsThisMonth = _snapsThisMonth(state);
    final snapsSub = totalSnaps == 0
        ? 'No snapshots yet'
        : '$totalSnaps total${snapsThisMonth > 0 ? ' · $snapsThisMonth this month' : ''}';

    final weightSub = state.weightLogs.isEmpty
        ? 'No weights logged'
        : '${state.weightLogs.length} entries · latest ${state.weightLogs.last.kg.toStringAsFixed(1)} kg';

    final profileSub = profile.isEmpty
        ? 'Tap to set up'
        : [
            if (profile.name != null && profile.name!.isNotEmpty) profile.name!,
            if (profile.age != null) '${profile.age} yrs',
          ].join(' · ');

    final notesSub = state.notes.isEmpty ? 'No notes yet' : '${state.notes.length} saved';
    final linksSub = state.links.isEmpty ? 'No links saved' : '${state.links.length} saved';
    final vaultSub = state.vault.isEmpty ? 'No entries · locked' : '${state.vault.length} entries · locked';

    final totalEntries = state.tasks.length
        + state.debts.length
        + state.events.length
        + totalSnaps
        + state.weightLogs.length
        + state.notes.length
        + state.links.length
        + state.vault.length;
    final since = DateTime.fromMillisecondsSinceEpoch(profile.createdAt);
    final displayName = (profile.name == null || profile.name!.isEmpty) ? 'Only me' : profile.name!;
    final initial = (profile.name != null && profile.name!.isNotEmpty)
        ? profile.name!.trim().substring(0, 1).toUpperCase()
        : 'M';

    final totalExpenses = state.expenses.fold<int>(0, (s, e) => s + e.amount);
    final expensesSub = state.expenses.isEmpty
        ? 'No expenses logged'
        : '${state.expenses.length} entries · $cur${_fmtK(totalExpenses)} total';

    final sections = <_Section>[
      _Section('Trackers', [
        _Item('tasks', 'Tasks', tasksSub, 'checkCircle', const Color(0xFF8B7CFF)),
        _Item('finance', 'Finance', financeSub, 'wallet', const Color(0xFF34D399)),
        _Item('events', 'Events', eventsSub, 'calendar', const Color(0xFFFB7185)),
        _Item('expenses', 'Expenses', expensesSub, 'receipt', const Color(0xFFFF8C42)),
      ]),
      _Section('Health', [
        _Item('gym', 'Gym', gymSub, 'dumbbell', const Color(0xFFF472B6)),
        _Item('snapshots', 'Snapshots', snapsSub, 'camera', const Color(0xFFFBBF24)),
        _Item('gym', 'Weight log', weightSub, 'trendUp', const Color(0xFF60A5FA)),
      ]),
      _Section('Memory', [
        _Item('notes', 'Notes', notesSub, 'note', const Color(0xFFA78BFA)),
        _Item('links', 'Saved links', linksSub, 'link', const Color(0xFF34D399)),
        _Item('vault', 'Vault', vaultSub, 'lock', const Color(0xFFEF4444)),
      ]),
      _Section('Account', [
        _Item('profile', 'Profile', profileSub, 'user', const Color(0xFF94A3B8)),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(theme: theme, greeting: const Greeting(sub: 'Settings & tools', title: 'More'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.settings, onTap: onOpenTweaks)]),

        // Profile header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 16,
            onTap: () => state.setScreen('profile'),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.accent, theme.accent2]),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: theme.ink)),
                  const SizedBox(height: 2),
                  Text('Since ${_monthYear(since)} · $totalEntries entries',
                      style: TextStyle(fontSize: 13, color: theme.muted)),
                ],
              )),
              GestureDetector(
                onTap: () => state.setScreen('profile'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: theme.rule, width: 1), borderRadius: BorderRadius.circular(10)),
                  child: Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.ink)),
                ),
              ),
            ]),
          ),
        ),

        for (final s in sections) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(s.head.toUpperCase(), style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1,
            )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(theme: theme, pad: 0, child: Column(children: [
              for (var i = 0; i < s.items.length; i++) _MoreRow(
                item: s.items[i],
                hasTop: i > 0,
                onTap: () => state.setScreen(s.items[i].key),
              ),
            ])),
          ),
        ],

        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Text('NOTIFICATIONS', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1,
          )),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _NotificationsSection(),
        ),

        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Text('BACKUP', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1,
          )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 0, child: Column(children: [
            _MoreRow(
              item: _Item('__export', 'Export data', 'Save all local data as JSON', 'trendUp', const Color(0xFF60A5FA)),
              hasTop: false,
              onTap: () => _runExport(context),
            ),
            _MoreRow(
              item: _Item('__import', 'Import data', 'Replace all data from JSON backup', 'refresh', const Color(0xFFF472B6)),
              hasTop: true,
              onTap: () => _runImport(context),
            ),
          ])),
        ),

        const SizedBox(height: 28),
        Center(child: Text('Only me · v1.0 · made with ♡', style: TextStyle(fontSize: 11, color: theme.muted))),
      ],
    );
  }

  Future<void> _runExport(BuildContext context) async {
    final state = context.read<AppState>();
    try {
      await exportAll(state);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _runImport(BuildContext context) async {
    final ok = await confirmDelete(
      context,
      title: 'Replace all data?',
      message: 'Importing will overwrite tasks, debts, events, gym, snapshots, notes, links, vault and profile with the contents of the chosen backup file.',
      confirmLabel: 'Choose file',
      icon: LucideIcons.upload,
    );
    if (!ok) return;
    if (!context.mounted) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.single.path == null) return;

    if (!context.mounted) return;
    final state = context.read<AppState>();
    final result = await importAll(state, File(picked.files.single.path!));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }
}

class _MoreRow extends StatelessWidget {
  final _Item item;
  final bool hasTop;
  final VoidCallback onTap;
  const _MoreRow({required this.item, required this.hasTop, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: hasTop ? BoxDecoration(border: Border(top: BorderSide(color: theme.rule, width: 1))) : null,
          child: Row(children: [
            IconChip(bg: item.color.withOpacity(0.13), size: 36, child: Icon(AppIcons.byKey(item.icon), color: item.color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.1)),
                const SizedBox(height: 1),
                Text(item.sub, style: TextStyle(fontSize: 12, color: theme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            Icon(LucideIcons.chevronRight, color: theme.muted, size: 16),
          ]),
        ),
      ),
    );
  }
}

class _Section {
  final String head;
  final List<_Item> items;
  const _Section(this.head, this.items);
}

class _Item {
  final String key;
  final String label;
  final String sub;
  final String icon;
  final Color color;
  const _Item(this.key, this.label, this.sub, this.icon, this.color);
}

String _monthYear(DateTime d) {
  const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${abbrs[d.month - 1]} ${d.year}';
}

String _fmtK(int n) {
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

// ── Notifications section (live permission status + test) ─────────────────────

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();
  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection>
    with WidgetsBindingObserver {
  bool _notifOk = true;
  bool _exactOk = true;
  bool _batteryOk = true;
  bool _testBusy = false;
  String? _testMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user returns from Settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final svc = NotificationsService.instance;
    final n = await svc.hasNotificationPermission();
    final e = await svc.hasExactAlarmPermission();
    final b = await svc.isBatteryOptimizationDisabled();
    if (!mounted) return;
    setState(() { _notifOk = n; _exactOk = e; _batteryOk = b; });
  }

  Future<void> _sendTest() async {
    setState(() { _testBusy = true; _testMsg = null; });
    final result = await NotificationsService.instance.sendTestNotification();
    if (!mounted) return;
    setState(() {
      _testBusy = false;
      _testMsg = result == 'ok'
          ? 'Test notification scheduled — look for it in ~10 seconds'
          : 'Failed: $result';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return Column(children: [
      // Permission status card
      AppCard(theme: theme, pad: 0, child: Column(children: [
        _PermRow(
          theme: theme,
          icon: LucideIcons.bell,
          label: 'Notifications',
          ok: _notifOk,
          fixLabel: 'Grant',
          onFix: () async {
            await NotificationsService.instance.requestPermission();
            _refresh();
          },
        ),
        _PermRow(
          theme: theme,
          icon: LucideIcons.alarmClock,
          label: 'Exact alarms',
          subLabel: 'Settings → Special app access → Alarms & reminders',
          ok: _exactOk,
          fixLabel: 'Open settings',
          onFix: () async {
            await NotificationsService.instance.openExactAlarmSettings();
            _refresh();
          },
          hasTop: true,
        ),
        _PermRow(
          theme: theme,
          icon: LucideIcons.zap,
          label: 'Battery unrestricted',
          subLabel: 'Settings → Apps → Only Me → Battery → Unrestricted',
          ok: _batteryOk,
          fixLabel: 'Open settings',
          onFix: () async {
            await NotificationsService.instance.requestBatteryOptimizationExemption();
            _refresh();
          },
          hasTop: true,
        ),
      ])),

      const SizedBox(height: 10),

      // Test notification button
      GestureDetector(
        onTap: _testBusy ? null : _sendTest,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.accent.withOpacity(0.35)),
          ),
          child: Row(children: [
            Icon(_testBusy ? LucideIcons.loader : LucideIcons.send,
                color: theme.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Send test notification',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.accent)),
              if (_testMsg != null)
                Text(_testMsg!,
                    style: TextStyle(fontSize: 11, color: theme.muted, height: 1.3)),
              if (_testMsg == null)
                Text('Fires in 10 s — confirms the pipeline works',
                    style: TextStyle(fontSize: 11, color: theme.muted)),
            ])),
          ]),
        ),
      ),

      const SizedBox(height: 10),

      // Alarm sound picker
      AppCard(theme: theme, pad: 0, child: _AlarmSoundRow(theme: theme)),
    ]);
  }
}

class _PermRow extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final String? subLabel;
  final bool ok;
  final String fixLabel;
  final VoidCallback onFix;
  final bool hasTop;
  const _PermRow({
    required this.theme,
    required this.icon,
    required this.label,
    this.subLabel,
    required this.ok,
    required this.fixLabel,
    required this.onFix,
    this.hasTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ok ? const Color(0xFF22C55E) : theme.danger;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: hasTop ? BoxDecoration(border: Border(top: BorderSide(color: theme.rule, width: 1))) : null,
      child: Row(children: [
        Icon(icon, size: 18, color: ok ? theme.ink2 : theme.danger),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: ok ? theme.ink : theme.danger)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(ok ? 'Granted' : 'Missing',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          if (!ok && subLabel != null) ...[
            const SizedBox(height: 2),
            Text(subLabel!, style: TextStyle(fontSize: 10, color: theme.muted, height: 1.3)),
          ],
        ])),
        if (!ok)
          GestureDetector(
            onTap: onFix,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(fixLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.danger)),
            ),
          ),
      ]),
    );
  }
}

// ── Alarm sound picker ─────────────────────────────────────────────────────────

class _AlarmSoundRow extends StatelessWidget {
  final AppTheme theme;
  const _AlarmSoundRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final name = state.profile.alarmSoundName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pick(context, state),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            IconChip(
              bg: const Color(0xFF8B7CFF).withOpacity(0.13), size: 36,
              child: const Icon(LucideIcons.music, color: Color(0xFF8B7CFF), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Alarm sound', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.1)),
              const SizedBox(height: 1),
              Text(
                name ?? 'System default',
                style: TextStyle(fontSize: 12, color: name != null ? theme.accent : theme.muted),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ])),
            if (name != null)
              GestureDetector(
                onTap: () => state.setAlarmSound(path: null, name: null),
                behavior: HitTestBehavior.opaque,
                child: Padding(padding: const EdgeInsets.all(6), child: Icon(LucideIcons.x, size: 16, color: theme.muted)),
              ),
            Icon(LucideIcons.chevronRight, color: theme.muted, size: 16),
          ]),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, AppState state) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (picked == null || picked.files.single.path == null) return;

    final src = File(picked.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();
    final alarmsDir = Directory('${dir.path}/alarms');
    if (!alarmsDir.existsSync()) alarmsDir.createSync(recursive: true);

    final ext = picked.files.single.extension ?? 'mp3';
    final dest = File('${alarmsDir.path}/alarm_sound.$ext');
    await src.copy(dest.path);

    if (!context.mounted) return;
    state.setAlarmSound(path: dest.path, name: picked.files.single.name);
  }
}

int _snapsThisMonth(AppState state) {
  final now = DateTime.now();
  int count = 0;
  for (final list in state.snapshots.values) {
    for (final s in list) {
      final ts = DateTime.fromMillisecondsSinceEpoch(s.id);
      if (ts.year == now.year && ts.month == now.month) count++;
    }
  }
  return count;
}
