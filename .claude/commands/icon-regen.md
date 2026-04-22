---
description: Regenerate the app icon from tool/render_icon.dart and propagate to iOS + Android
argument-hint: (no args)
allowed-tools: Bash, Read
---

Run the OnlyMe icon pipeline end-to-end.

1. Run `flutter test tool/render_icon.dart` to re-render `assets/icon/app_icon.png` and `assets/icon/app_icon_fg.png` from Dart source.
2. Run `flutter pub run flutter_launcher_icons` to propagate the master to every iOS size (`ios/Runner/Assets.xcassets/AppIcon.appiconset/*`), Android mipmap (`android/app/src/main/res/mipmap-*/ic_launcher.png`), adaptive icon foreground (`drawable-*`), and the adaptive icon XML.
3. List the touched files so the user can verify before committing.

Notes:
- Both commands must succeed. If the `flutter test` step hangs, the fix is almost always that the renderer lost its `tester.runAsync` wrap — see `docs/icon-pipeline.md`.
- Do NOT commit anything automatically. Just regenerate and report.
- Don't rebuild the APK after — that's `/ship-apk`.
