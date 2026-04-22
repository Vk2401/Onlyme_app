# App icon pipeline

The icon is **not** a hand-authored PNG. It's a Flutter canvas drawing rendered headlessly and then propagated to every iOS/Android size by `flutter_launcher_icons`.

## Why generate it?

- Changes are code reviews, not binary diffs.
- The source is `tool/render_icon.dart` — 120 lines of `Canvas` calls. Anyone who can read Flutter can tweak the design.
- The pipeline runs on CI so the built APK always has icons rendered from the current source.

## Files

| Path | Purpose |
|---|---|
| `tool/render_icon.dart` | The drawing (full-bleed + transparent foreground). Runs as a Flutter test. |
| `assets/icon/app_icon.png` | **Generated.** 1024×1024 master with gradient background. |
| `assets/icon/app_icon_fg.png` | **Generated.** 1024×1024 transparent foreground (glyph only) for Android adaptive icons. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` | **Generated** by `flutter_launcher_icons` from `app_icon.png`. |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | **Generated.** Classic launcher icons. |
| `android/app/src/main/res/drawable-*/ic_launcher_foreground.png` | **Generated.** Adaptive foreground. |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | **Generated.** Adaptive-icon XML referencing the colour + foreground. |
| `android/app/src/main/res/values/colors.xml` | **Generated.** `ic_launcher_background = #0F766E`. |
| `pubspec.yaml` (`flutter_launcher_icons:` block) | Config — paths, adaptive colours, `remove_alpha_ios: true`. |

All "Generated" files are committed so release builds don't need to run the pipeline.

## Regenerate locally

```bash
flutter test tool/render_icon.dart       # writes assets/icon/app_icon{,_fg}.png
flutter pub run flutter_launcher_icons   # propagates to every iOS + Android size
```

Both commands are idempotent. Commit everything under `assets/icon/`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, and `android/app/src/main/res/*`.

## Regenerate on CI

`.github/workflows/build-apk.yml` runs these two steps before `flutter analyze` on every push to `main` / `master` / `claude/**`. See [ci.md](ci.md).

## The design

- **Background.** Full-bleed linear gradient (top-left → bottom-right): mint `#5EEAD4` → teal `#2DD4BF` → violet `#7C3AED`. Mirrors the app's home-hero-card gradient.
- **Soft highlight.** A radial white glow top-left at ~28% alpha — gives the icon an iOS-style sheen.
- **Glyph.** A bold white "M" (for "Me") drawn with thick rounded strokes. Subtle drop shadow.
- **Badge.** A dark rounded circle (navy gradient) in the bottom-right with a mint checkmark inside — signals "personal tracker / checklist."

If you change colours or shape, keep the glyph centred enough that Android adaptive-icon masking (~20% inset) doesn't clip it.

## Why `tester.runAsync` is required

The renderer calls `picture.toImage(1024, 1024)` and `image.toByteData(format: PNG)`. Those are real async operations backed by Skia — they don't resolve in the fake async zone that `testWidgets` uses by default. Wrapping the body in `tester.runAsync(() async { … })` routes the awaits to the real clock. Without it the test hangs until Flutter's listener timeout kills it.
