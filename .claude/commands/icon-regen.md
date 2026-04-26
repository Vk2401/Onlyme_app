---
description: Propagate assets/icon/app_icon{,_fg}.png to iOS + Android platform sizes
argument-hint: (no args)
allowed-tools: Bash, Read
---

Run the OnlyMe icon pipeline.

1. Run `flutter pub run flutter_launcher_icons` to propagate `assets/icon/app_icon.png` (opaque master) and `assets/icon/app_icon_fg.png` (transparent foreground) to every iOS size (`ios/Runner/Assets.xcassets/AppIcon.appiconset/*`), Android mipmap (`android/app/src/main/res/mipmap-*/ic_launcher.png`), adaptive icon foreground (`drawable-*`), and the adaptive icon XML.
2. List the touched files so the user can verify before committing.

Notes:
- To change the icon, replace `assets/icon/app_icon.png` and/or `assets/icon/app_icon_fg.png` first, then run this command.
- `assets/images/logo.png` is the transparent in-app logo (used in More screen). It is separate from the launcher icon and is NOT propagated by `flutter_launcher_icons`.
- Do NOT commit anything automatically. Just regenerate and report.
- Don't rebuild the APK after — that's `/ship-apk`.
