import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/app_icons.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback onOpenTweaks;
  final Future<void> Function() onSync;
  const MoreScreen({super.key, required this.onOpenTweaks, required this.onSync});

  static final sections = <_Section>[
    _Section('Health', [
      _Item('gym', 'Gym', 'Cutting · Week 3', 'dumbbell', Color(0xFFF472B6)),
      _Item('skincare', 'Skincare', 'AM & PM routines', 'droplet', Color(0xFF60A5FA)),
      _Item('snapshots', 'Snapshots', '9 new this month', 'camera', Color(0xFFFBBF24)),
    ]),
    _Section('Memory', [
      _Item('notes', 'Notes', '23 · 4 pinned', 'note', Color(0xFFA78BFA)),
      _Item('links', 'Saved links', '58 · sorted by tag', 'link', Color(0xFF34D399)),
    ]),
    _Section('Private', [
      _Item('vault', 'Vault', '14 entries · locked', 'lock', Color(0xFFEF4444)),
      _Item('profile', 'Profile', 'Vasanth · 28', 'user', Color(0xFF94A3B8)),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final last = state.lastSyncAt;
    final lastStr = last == null
        ? 'Never synced'
        : 'Last synced ${_ago(last)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(theme: theme, greeting: const Greeting(sub: 'Settings & tools', title: 'More'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.settings, onTap: onOpenTweaks)]),

        // Profile header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 16, child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.accent, theme.accent2]),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text('V', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vasanth', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: theme.ink)),
                const SizedBox(height: 2),
                Text('Since Jan 2024 · 112 entries', style: TextStyle(fontSize: 13, color: theme.muted)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: theme.rule, width: 1), borderRadius: BorderRadius.circular(10)),
              child: Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.ink)),
            ),
          ])),
        ),

        // Sync card (placeholder for future Claude sync)
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 16, child: Row(children: [
            IconChip(
              bg: theme.accent.withOpacity(0.15),
              size: 44,
              child: Icon(LucideIcons.cloud, color: theme.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync to Claude', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink)),
                const SizedBox(height: 2),
                Text(lastStr, style: TextStyle(fontSize: 12, color: theme.muted)),
              ],
            )),
            _SyncButton(onTap: onSync),
          ])),
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

        const SizedBox(height: 28),
        Center(child: Text('Only me · v1.0 · made with ♡', style: TextStyle(fontSize: 11, color: theme.muted))),
      ],
    );
  }
}

class _SyncButton extends StatefulWidget {
  final Future<void> Function() onTap;
  const _SyncButton({required this.onTap});
  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> with SingleTickerProviderStateMixin {
  bool busy = false;
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();

  @override
  void dispose() { _spin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return GestureDetector(
      onTap: busy ? null : () async {
        setState(() => busy = true);
        await widget.onTap();
        if (mounted) setState(() => busy = false);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: theme.glow, blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          RotationTransition(
            turns: busy ? _spin : const AlwaysStoppedAnimation(0),
            child: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 6),
          Text(busy ? 'Syncing' : 'Sync', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
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
                Text(item.sub, style: TextStyle(fontSize: 12, color: theme.muted)),
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

String _ago(DateTime then) {
  final d = DateTime.now().difference(then);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
