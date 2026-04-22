# Only me

A private, local-only personal tracker. Everything stays on your device — no accounts, no sync, no cloud.

<p align="center">
  <img src="assets/icon/app_icon.png" alt="Only me app icon" width="140" />
</p>

## What it tracks

- **Tasks** with daily streaks and completion.
- **Finance** — debts you owe and debts owed to you, with payment logging.
- **Events** with per-item budgets (estimated vs. actual spend).
- **Gym** — a weekly plan with per-exercise tracking and a body-weight log + chart.
- **Snapshots** — hair / body / skin visual journal (gradient placeholders for now).
- **Notes** — quick-capture text notes with created-date.
- **Saved links** — bookmarks that open in the external browser.
- **Vault** — a simple password store (title / username / password / URL / note).
- **Profile** — name, DOB, phone, and currency symbol (₹ / $ / € / £ / ¥ / custom).

All of it persists locally via `SharedPreferences` (JSON blobs), and the whole state round-trips through a single **export / import** JSON file.

## Design

- iOS-native dark aesthetic with four accent colors (violet / coral / mint / amber).
- Font: `Plus Jakarta Sans` via `google_fonts`.
- Screen transitions are bottom-to-top; destructive actions always show a confirmation sheet.

## Setup

```bash
flutter pub get
flutter run
```

If you don't have Flutter installed:

```bash
brew install --cask flutter
flutter doctor
```

## Build a release APK

```bash
flutter build apk --release --split-per-abi
```

CI (GitHub Actions) does this automatically on push to `main` and uploads the arm64 APK as an artifact — see [`docs/ci.md`](docs/ci.md).

## Backup & restore

Open **More → Backup → Export data** to hand the full JSON payload to the native share sheet (save to Files, email, AirDrop, etc.). **Import data** reads back a previously-exported file and replaces everything. Full spec in [`docs/backup.md`](docs/backup.md).

## App icon

The icon is rendered from Dart source (`tool/render_icon.dart`) and propagated to every iOS / Android size by `flutter_launcher_icons`. To change the art, edit the Dart, then run:

```bash
flutter test tool/render_icon.dart
flutter pub run flutter_launcher_icons
```

Details: [`docs/icon-pipeline.md`](docs/icon-pipeline.md).

## For contributors

- [`CLAUDE.md`](CLAUDE.md) — project rules, conventions, and Claude Code commands/agents shipped in `.claude/`.
- [`docs/`](docs/) — deep docs, one focused file per concern (architecture, state, storage, navigation, theme, models, screens, widgets, backup, icon, CI, testing, contributing).

Shortest possible primer:

1. State lives in **one** `ChangeNotifier` (`lib/app_state.dart`).
2. Storage is **one** wrapper class (`lib/storage/local_storage.dart`), JSON-encoded per-domain.
3. Navigation is **a string** on `AppState` + a `switch` in `AppShell` — no Navigator.
4. Theme is **a plain value object**, passed explicitly as `theme: …`.
5. Every destructive action goes through `confirmDelete()` in `lib/widgets/confirm_sheet.dart`.

To add a domain, follow the six-step walk-through in [`docs/contributing.md`](docs/contributing.md).

## Roadmap (known placeholders)

- **Sync** — `AppState.syncNow()` currently just stamps a local timestamp.
- **Snapshots** — the UI renders a gradient tile instead of real images.
- **Skincare** — currently a placeholder screen; no data model yet.
- **Vault encryption** — entries are plain JSON on disk; hardening is deferred.
