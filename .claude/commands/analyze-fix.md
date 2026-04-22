---
description: Run flutter analyze and fix every new issue introduced by recent changes
argument-hint: (no args)
allowed-tools: Bash, Read, Edit
---

Run `flutter analyze` and resolve every new issue introduced relative to the baseline.

Baseline (pre-existing, leave alone):
- `info • unnecessary_brace_in_string_interps` in `lib/screens/snapshots_screen.dart:63:28`
- `warning • unused_element_parameter` in `lib/screens/tasks_screen.dart:406:113`

Steps:
1. Run `flutter analyze`.
2. If the only issues reported are the two above, say "clean" and stop.
3. Otherwise, for each new issue:
   - Read the file + line.
   - Apply the smallest fix that addresses the root cause. Don't touch unrelated code.
   - Re-run analyze until only the baseline issues remain.
4. If you can't fix something (e.g. it's actually a bug in third-party code or needs context), STOP and explain — don't silence it.

Rules:
- Never add `// ignore:` comments.
- Never broaden types to `dynamic` to silence a warning.
- Never use `!` to shut up a null warning — fix the null handling instead.
- Don't run `dart fix` wholesale; we want deliberate changes only.
