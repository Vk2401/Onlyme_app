import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Greeting {
  final String sub;
  final String title;
  const Greeting({required this.sub, required this.title});
}

class AppHeader extends StatelessWidget {
  final AppTheme theme;
  final Greeting greeting;
  final List<Widget> right;
  const AppHeader({super.key, required this.theme, required this.greeting, this.right = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting.sub, style: TextStyle(
                  fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 2),
                Text(greeting.title, style: TextStyle(
                  fontSize: 24, color: theme.ink, fontWeight: FontWeight.w700, letterSpacing: -0.6,
                )),
              ],
            ),
          ),
          Row(children: [
            for (final w in right) Padding(padding: const EdgeInsets.only(left: 10), child: w),
          ]),
        ],
      ),
    );
  }
}

class HeaderBtn extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final bool badge;
  final VoidCallback? onTap;
  const HeaderBtn({super.key, required this.theme, required this.icon, this.badge = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.rule, width: 1),
        ),
        child: Stack(children: [
          Center(child: Icon(icon, size: 20, color: theme.ink)),
          if (badge) Positioned(
            top: 8, right: 8,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accent,
                border: Border.all(color: theme.bg, width: 2),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
