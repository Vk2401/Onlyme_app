import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/debt.dart';
import '../widgets/primitives.dart';
import '../widgets/header.dart';
import '../widgets/task_card.dart';
import '../widgets/app_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final pending = state.tasks.where((t) => !t.done).toList();
    final doneCount = state.tasks.length - pending.length;
    final pct = state.tasks.isEmpty ? 0.0 : doneCount / state.tasks.length;
    final iOwe = state.debts
        .where((d) => d.type == DebtType.iOwe && !d.settled)
        .fold<int>(0, (s, d) => s + d.remain);
    final owedMe = state.debts
        .where((d) => d.type == DebtType.theyOwe && !d.settled)
        .fold<int>(0, (s, d) => s + d.remain);
    final next = state.events.isEmpty ? null : state.events.first;
    final cur = state.profile.currencySymbol;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Welcome back', title: 'Only me'),
          right: [
            HeaderBtn(theme: theme, icon: LucideIcons.bell),
          ],
        ),

        // Hero progress card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _HeroCard(pct: pct, doneCount: doneCount, total: state.tasks.length),
        ),

        const SizedBox(height: 12),

        // Finance quick stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: _StatCard(
              title: 'Owed to me',
              value: owedMe == 0 ? '${cur}0' : '$cur${_fmtK(owedMe)}',
              icon: LucideIcons.arrowDown,
              color: theme.success,
              onTap: () => state.setScreen('finance'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              title: 'I owe',
              value: iOwe == 0 ? '${cur}0' : '$cur${_fmtK(iOwe)}',
              icon: LucideIcons.arrowUp,
              color: theme.danger,
              onTap: () => state.setScreen('finance'),
            )),
          ]),
        ),

        const SizedBox(height: 22),

        // Up next tasks
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            theme: theme, title: 'Up next', action: 'See all',
            onAction: () => state.setScreen('tasks'),
          ),
        ),
        const SizedBox(height: 12),

        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 18,
              child: Row(children: [
                Icon(LucideIcons.checkCircle, color: theme.success, size: 20),
                const SizedBox(width: 10),
                Text('All tasks done!', style: TextStyle(fontSize: 14, color: theme.ink, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('Add more in Tasks', style: TextStyle(fontSize: 13, color: theme.muted)),
              ]),
            ),
          )
        else
          for (final t in pending.take(3))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TaskCardWidget(task: t, theme: theme, onToggle: () => state.toggleTask(t.id)),
            ),

        const SizedBox(height: 12),

        // Coming up events
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            theme: theme, title: 'Coming up', action: 'All events',
            onAction: () => state.setScreen('events'),
          ),
        ),
        const SizedBox(height: 12),

        if (next == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 18,
              onTap: () => state.setScreen('events'),
              child: Row(children: [
                Icon(LucideIcons.calendar, color: theme.muted, size: 20),
                const SizedBox(width: 10),
                Text('No events planned yet', style: TextStyle(fontSize: 14, color: theme.muted)),
                const Spacer(),
                Icon(LucideIcons.plus, size: 16, color: theme.accent),
              ]),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 16,
              onTap: () => state.setScreen('events'),
              child: Row(children: [
                IconChip(
                  bg: next.color.withOpacity(0.13),
                  size: 48,
                  child: Icon(AppIcons.byKey(next.icon), color: next.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(next.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.2)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(LucideIcons.calendar, size: 12, color: theme.muted),
                    const SizedBox(width: 5),
                    Flexible(child: Text(
                      '${next.date} · ${next.doneCount}/${next.items.length} ready',
                      style: TextStyle(fontSize: 12, color: theme.muted),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${next.daysAway}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.accent, letterSpacing: -0.6)),
                  Text('DAYS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: theme.muted, letterSpacing: 0.5)),
                ]),
              ]),
            ),
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double pct;
  final int doneCount;
  final int total;
  const _HeroCard({required this.pct, required this.doneCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.accent, theme.accent2],
          ),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(right: -30, top: -30, child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.12)),
          )),
          Positioned(right: 40, bottom: -40, child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
          )),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's progress", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('$doneCount', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
                const SizedBox(width: 6),
                Text('of $total done', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8))),
              ]),
              if (total == 0) ...[
                const SizedBox(height: 8),
                Text('Tap + in Tasks to add your first task', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
              ],
            ])),
            Ring(
              pct: pct, size: 72, stroke: 6,
              color: Colors.white,
              track: Colors.white.withOpacity(0.25),
              child: Text('${(pct * 100).round()}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return AppCard(
      theme: theme, pad: 14, onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconChip(bg: color.withOpacity(0.15), size: 28, child: Icon(icon, color: color, size: 14)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.4)),
      ]),
    );
  }
}

String _fmtK(int n) {
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
