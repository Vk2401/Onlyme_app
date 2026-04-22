import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';

class PlaceholderScreen extends StatelessWidget {
  final String label;
  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: Greeting(sub: 'Coming soon', title: label),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.plus)],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            theme: theme, pad: 30,
            child: Column(children: [
              IconChip(
                bg: theme.accent.withOpacity(0.13),
                size: 56,
                child: Icon(LucideIcons.sparkles, color: theme.accent, size: 28),
              ),
              const SizedBox(height: 14),
              Text('$label is almost ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
              const SizedBox(height: 6),
              SizedBox(
                width: 240,
                child: Text(
                  'Full CRUD, search & filters. Wired to the same data model as the rest of the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.muted, height: 1.5),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
