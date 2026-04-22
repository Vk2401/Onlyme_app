import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Segmented<T> extends StatelessWidget {
  final List<MapEntry<T, String>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final AppTheme theme;

  const Segmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.rule, width: 1),
      ),
      child: Row(children: [
        for (final entry in items)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: value == entry.key ? theme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value == entry.key ? Colors.white : theme.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
