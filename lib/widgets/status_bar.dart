import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Removed fake iOS status-bar mockup — the real OS status bar is shown instead.
class PhoneStatusBar extends StatelessWidget {
  final AppTheme theme;
  const PhoneStatusBar({super.key, required this.theme});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
