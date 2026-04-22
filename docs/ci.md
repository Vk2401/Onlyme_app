# CI (GitHub Actions)

One workflow: `.github/workflows/build-apk.yml`.

## Triggers

- Push to `main`, `master`, or any branch matching `claude/**`.
- Manual via `workflow_dispatch`.

## Pipeline

```
actions/checkout@v4
  ↓
setup-java (temurin 17)
  ↓
subosito/flutter-action@v2 (flutter 3.24.5, stable, cache: true)
  ↓
flutter pub get
  ↓
flutter test tool/render_icon.dart      ← regenerate icon master PNGs
  ↓
flutter pub run flutter_launcher_icons  ← propagate to iOS + Android
  ↓
flutter analyze --no-fatal-infos
  ↓
flutter build apk --release --split-per-abi
  ↓
cp build/app/outputs/apk/release/app-arm64-v8a-release.apk releases/onlyme-v1.1.apk
  ↓
actions/upload-artifact@v4 (retention 30 days)
```

The artifact `onlyme-release-apk` is available on the run's summary page.

## Why `--no-fatal-infos`?

The analyzer currently reports two pre-existing `info`-level issues:

- `unnecessary_brace_in_string_interps` in `snapshots_screen.dart:63:28`
- `unused_element_parameter` in `tasks_screen.dart:406:113`

Both predate the recent work. The flag lets `flutter analyze` still catch real errors (they stay fatal) while tolerating these stylistic infos. Warnings and errors still fail the build.

## Why regenerate the icon on every push?

- The source of truth for the icon is `tool/render_icon.dart`. Having CI re-render removes the risk of "I forgot to commit the PNGs" drift.
- The generated PNGs *are* still committed so contributors don't need to run Flutter locally to see them in a diff, but CI rebuilds them from the current Dart source anyway. Deterministic.

## Adding a step

Typical additions:

- **Unit tests:** insert `flutter test` before `flutter analyze`. The icon test is `flutter test tool/render_icon.dart` specifically — running `flutter test` without an argument will run that too, so be explicit if you want them separated.
- **Multi-platform APK:** the current build is arm64 only. Change `cp …/app-arm64-v8a-release.apk …` to upload all three split APKs if you add `x86_64` users.
- **iOS build:** requires `runs-on: macos-latest` and Xcode provisioning. Not worth adding until there's a TestFlight target.

## Secrets

None. The repo has no API keys, no signing key upload. Android signing uses the default debug key in `android/app/build.gradle` — release builds are unsigned-ish. If you ever need to publish to Google Play, add an upload-keystore secret and a dedicated signing step.
