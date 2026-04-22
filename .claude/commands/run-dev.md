---
description: Start flutter run on a connected device/simulator in the background
argument-hint: [device-id] (optional; omit to let Flutter pick)
allowed-tools: Bash
---

Start `flutter run` on a device so the user can hot-reload while iterating.

1. If `$1` is provided, pass `-d $1`. Otherwise run without `-d` and let Flutter pick.
2. Run `flutter run` in the background (`run_in_background: true`) so the output doesn't flood the chat.
3. Report the background task ID so the user can check logs with Read on the task output file.
4. Remind the user they can press `r` for hot reload and `q` to quit — but note that `q` requires interactive input, which this harness doesn't support, so to stop the app they should kill the background task via TaskStop.

Do not invoke hot-reload yourself — Flutter's `r` requires an interactive TTY. If the user asks to reload, suggest they save a file (auto-reload via IDE) or kill and restart.
