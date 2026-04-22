import 'package:flutter/material.dart';

enum AccentKey { violet, coral, mint, amber }

class Accent {
  final Color a;
  final Color a2;
  final Color glow;
  const Accent(this.a, this.a2, this.glow);
}

const Map<AccentKey, Accent> accents = {
  AccentKey.violet: Accent(Color(0xFF8B7CFF), Color(0xFF6D5CFF), Color(0x408B7CFF)),
  AccentKey.coral:  Accent(Color(0xFFFF8A6B), Color(0xFFFF6B47), Color(0x40FF8A6B)),
  AccentKey.mint:   Accent(Color(0xFF5EEAD4), Color(0xFF2DD4BF), Color(0x405EEAD4)),
  AccentKey.amber:  Accent(Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0x40FBBF24)),
};

class AppTheme {
  final bool dark;
  final AccentKey accentKey;

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color rule;
  final Color danger;
  final Color success;
  final Color warning;
  final Color accent;
  final Color accent2;
  final Color glow;

  const AppTheme._({
    required this.dark,
    required this.accentKey,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.rule,
    required this.danger,
    required this.success,
    required this.warning,
    required this.accent,
    required this.accent2,
    required this.glow,
  });

  factory AppTheme.build({required bool dark, required AccentKey accentKey}) {
    final acc = accents[accentKey]!;
    return AppTheme._(
      dark: dark,
      accentKey: accentKey,
      bg: dark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F7),
      surface: dark ? const Color(0xFF16161F) : const Color(0xFFFFFFFF),
      surface2: dark ? const Color(0xFF1E1E2A) : const Color(0xFFF1F1F5),
      ink: dark ? const Color(0xFFF5F5F7) : const Color(0xFF0F0F14),
      ink2: dark ? const Color(0xFFC0C0CC) : const Color(0xFF3A3A44),
      muted: dark ? const Color(0xFF7A7A8C) : const Color(0xFF8A8A94),
      rule: dark ? const Color(0x14FFFFFF) : const Color(0x14000000),
      danger: const Color(0xFFEF4444),
      success: const Color(0xFF22C55E),
      warning: const Color(0xFFF59E0B),
      accent: acc.a,
      accent2: acc.a2,
      glow: acc.glow,
    );
  }

  AppTheme copyWith({bool? dark, AccentKey? accentKey}) {
    return AppTheme.build(
      dark: dark ?? this.dark,
      accentKey: accentKey ?? this.accentKey,
    );
  }
}
