import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';

class TweaksSheet extends StatelessWidget {
  final VoidCallback onClose;
  const TweaksSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    return Positioned(
      right: 16, top: 60,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.rule, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 60, offset: const Offset(0, 20))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tweaks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.ink)),
              GestureDetector(
                onTap: onClose,
                child: Icon(LucideIcons.x, size: 18, color: theme.muted),
              ),
            ]),
            const SizedBox(height: 14),
            Text('ACCENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final k in AccentKey.values)
                _Pill(
                  active: state.theme.accentKey == k,
                  label: k.name,
                  swatch: accents[k]!.a,
                  onTap: () => state.setAccent(k),
                ),
            ]),
            const SizedBox(height: 16),
            Text('THEME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(children: [
              _Pill(
                active: state.theme.dark, label: 'dark',
                swatch: const Color(0xFF16161F),
                onTap: () => state.setDark(true),
              ),
              const SizedBox(width: 6),
              _Pill(
                active: !state.theme.dark, label: 'light',
                swatch: const Color(0xFFFFFFFF),
                onTap: () => state.setDark(false),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final bool active;
  final String label;
  final Color swatch;
  final VoidCallback onTap;
  const _Pill({required this.active, required this.label, required this.swatch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.accent : theme.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : theme.ink2),
          ),
        ]),
      ),
    );
  }
}
