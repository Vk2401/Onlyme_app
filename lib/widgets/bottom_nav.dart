import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;
  final AppTheme theme;

  static const moreKeys = ['tasks', 'snapshots', 'skincare', 'notes', 'links', 'vault', 'profile', 'events', 'more'];

  const BottomNav({super.key, required this.active, required this.onChange, required this.theme});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('home', 'Home', LucideIcons.home),
      _NavItem('gym', 'Workout', LucideIcons.dumbbell),
      _NavItem('add', '', LucideIcons.plus, fab: true),
      _NavItem('finance', 'Finance', LucideIcons.wallet),
      _NavItem('more', 'More', LucideIcons.moreHorizontal),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 26),
          decoration: BoxDecoration(
            color: theme.dark
                ? const Color(0xFF0A0A0F).withOpacity(0.85)
                : const Color(0xFFF5F5F7).withOpacity(0.85),
            border: Border(top: BorderSide(color: theme.rule, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final it in items) _buildItem(it),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_NavItem it) {
    if (it.fab) {
      return GestureDetector(
        onTap: () => onChange('add'),
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [theme.accent, theme.accent2],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: theme.glow, blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
          ),
        ),
      );
    }
    final on = active == it.k || (it.k == 'more' && moreKeys.contains(active));
    final color = on ? theme.accent : theme.muted;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(it.k),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(it.icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(it.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String k;
  final String label;
  final IconData icon;
  final bool fab;
  _NavItem(this.k, this.label, this.icon, {this.fab = false});
}
