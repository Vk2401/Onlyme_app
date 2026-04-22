# Only me

Private personal tracker — tasks, finance, events, gym, snapshots. Built from the
React HTML design preview (`Only me.html`) as a native Flutter app with local
persistence and iOS-style smooth transitions.

## Features
- Home dashboard with progress ring, finance quick stats, up-next tasks, next event
- Tasks with streaks and completion
- Finance: i-owe / they-owe debts, payment logging via bottom sheet
- Events with checklist + est vs spent budget
- Gym: weekly plan, per-exercise tracking, weight chart
- Snapshots: hair / body / skin visual journal (placeholder photos)
- More: profile, sync-to-Claude button (local stamp only for now), sub-sections
- Tweaks sheet: accent (violet/coral/mint/amber) + dark/light
- All state persisted locally via SharedPreferences (JSON)
- iOS-style cross-fade + slide screen transitions

## Setup

The lib/ source is ready. You need to generate platform folders once:

```bash
cd onlyme
flutter create . --org com.webronic --platforms ios,android,macos,web
flutter pub get
flutter run
```

If you don't have Flutter:

```bash
brew install --cask flutter
flutter doctor
```

## Sync placeholder

`MoreScreen` has a "Sync to Claude" button wired to `AppState.syncNow()`. Today it
just records a local timestamp. The JSON shape lives in `lib/storage/local_storage.dart`
— future work is to POST that payload to a sync endpoint.

## Data model

- `lib/models/` — Task, Debt, Event, Gym, Snapshot
- `lib/data/seed_data.dart` — seed data (matches the HTML mock)
- `lib/storage/local_storage.dart` — JSON ↔ SharedPreferences
- `lib/app_state.dart` — ChangeNotifier that owns all state
