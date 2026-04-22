import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

/// Bottom-sheet confirmation dialog used by every destructive action.
/// Returns true if the user taps the confirm button, false otherwise.
Future<bool> confirmDelete(
  BuildContext ctx, {
  required String title,
  String? message,
  String confirmLabel = 'Delete',
  IconData icon = LucideIcons.trash2,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: ctx,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    isScrollControlled: true,
    builder: (sheetCtx) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: icon,
    ),
  );
  return result == true;
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final IconData icon;
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.rule),
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 22),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: theme.danger.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: theme.danger, size: 26),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.3)),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.muted, height: 1.4)),
        ],
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.rule),
              ),
              alignment: Alignment.center,
              child: Text('Cancel', style: TextStyle(fontSize: 14, color: theme.ink, fontWeight: FontWeight.w600)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.danger,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(confirmLabel, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          )),
        ]),
      ]),
    );
  }
}
