# App icon pipeline

The launcher icon is a **direct PNG asset** — no code generation step. `flutter_launcher_icons` propagates the master PNG to every iOS and Android size.

## Files

| Path | Purpose |
|---|---|
| `assets/icon/app_icon.png` | Master 1024×1024 launcher icon (opaque background). Edit this to change the icon. |
| `assets/icon/app_icon_fg.png` | Master 1024×1024 transparent foreground for Android adaptive icons (glyph/logo only, no background). |
| `assets/images/logo.png` | Transparent logo used inside the app (More screen profile card and footer). |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` | **Generated** by `flutter_launcher_icons` from `app_icon.png`. |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | **Generated.** Classic launcher icons. |
| `android/app/src/main/res/drawable-*/ic_launcher_foreground.png` | **Generated.** Adaptive foreground. |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | **Generated.** Adaptive-icon XML referencing the background colour + foreground. |
| `android/app/src/main/res/values/colors.xml` | **Generated.** `ic_launcher_background = #FFFFFF`. |
| `pubspec.yaml` (`flutter_launcher_icons:` block) | Config — paths, adaptive background colour, `remove_alpha_ios: true`. |

All "Generated" files are committed so release builds don't need to run the pipeline.

## Regenerate locally

Replace `assets/icon/app_icon.png` and/or `assets/icon/app_icon_fg.png`, then run:

```bash
flutter pub run flutter_launcher_icons
```

Commit everything under `assets/icon/`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, and `android/app/src/main/res/*`.

## Regenerate on CI

`.github/workflows/build-apk.yml` runs `flutter pub run flutter_launcher_icons` before `flutter analyze` on every push to `main` / `master` / `claude/**`. This ensures the committed PNGs are always in sync with `pubspec.yaml` config. See [ci.md](ci.md).

## In-app logo

`assets/images/logo.png` (transparent) is a separate asset used inside the app — it is **not** the launcher icon source. It's displayed in the More screen profile card and the footer. If you replace the logo, update both `assets/icon/app_icon_fg.png` and `assets/images/logo.png`.
