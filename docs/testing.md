# Testing

There are no unit tests yet. This doc captures how to run what exists and how to add new tests.

## Run everything

```bash
flutter test
```

This runs every file under `test/`.

## Analyze

```bash
flutter analyze
```

Expected output after a clean build: `2 issues found` (the two pre-existing infos — see [ci.md](ci.md)).

## Where to put unit tests

Put Flutter-agnostic model tests under `test/models/` (e.g. `test/models/profile_test.dart`). Put widget tests under `test/widgets/`. Match the source folder structure so it's obvious what tests cover what.

Model tests can be plain `test()` — no widget binding needed. Anything that paints needs `testWidgets()`.

## What's worth testing first?

In priority order:

1. **`AppState.reloadFromStorage()`** — the import path. A single test that writes a known JSON payload to SharedPreferences, calls reload, and asserts every field is populated correctly catches the whole round-trip.
2. **Model `fromJson`/`toJson` round-trips** — one test per model, asserting `m == Model.fromJson(m.toJson())`. Catches new fields that were added to `toJson` but forgotten in `fromJson` (or vice versa).
3. **`confirmDelete` helper** — `testWidgets` that taps Cancel/Delete and asserts the returned `bool`.

## Mocking SharedPreferences

```dart
SharedPreferences.setMockInitialValues({});
final storage = LocalStorage(await SharedPreferences.getInstance());
```

This is the canonical pattern for any test that wants a fresh in-memory store.

## CI

`.github/workflows/build-apk.yml` runs `flutter pub run flutter_launcher_icons` (to propagate icon assets) and `flutter analyze --no-fatal-infos`. If you add a `flutter test` step, insert it before `flutter analyze`.
