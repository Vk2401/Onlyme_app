---
description: Build a release APK, copy to releases/, and report the size
argument-hint: [version] (optional, e.g. "1.2" — defaults to pubspec version)
allowed-tools: Bash, Read
---

Build a release APK exactly the same way CI does and drop it into `releases/`.

1. Read the current version from `pubspec.yaml` (the `version:` line; take the part before `+`).
2. If the user passed `$1`, use that as the version label for the filename; otherwise use the pubspec version.
3. Run, in order:
   - `flutter pub get`
   - `flutter analyze` — if it reports anything other than the two baseline infos, STOP and show the output. Don't ship with new issues.
   - `flutter build apk --release --split-per-abi`
4. Copy `build/app/outputs/apk/release/app-arm64-v8a-release.apk` to `releases/onlyme-v<version>.apk` (create the dir if missing).
5. Report the file path + size (`du -sh`).

Do NOT run the icon pipeline here — if the user wants fresh icons, they'll run `/icon-regen` first. Don't push to git, don't create a release, don't tag.

If any step fails, surface the error verbatim and stop.
