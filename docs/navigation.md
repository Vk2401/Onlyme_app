# Navigation

## TL;DR

- **No `Navigator`, no routes, no `go_router`.**
- Current screen is a `String` field on `AppState`.
- `AppShell.build` has a `switch (state.screen)` that returns the right widget.
- Changing screens: `state.setScreen('notes')`.
- Screen change persists to `onlyme:screen` so the app reopens on the last screen.

## Why this and not a router package?

The app is a single-level navigation model: bottom-nav tabs + a few "deep" screens reachable from More. There are zero nested navigators, no deep-link URLs, no platform-level back-stack expectations. A router package would add configuration and a learning tax for no gain.

## Valid screen keys

| Key | Widget |
|---|---|
| `home` | `HomeScreen` |
| `tasks` | `TasksScreen` |
| `finance` | `FinanceScreen` |
| `events` | `EventsScreen` |
| `gym` | `GymScreen` |
| `snapshots` | `SnapshotsScreen` |
| `more` | `MoreScreen` |
| `profile` | `ProfileScreen` |
| `notes` | `NotesScreen` |
| `links` | `LinksScreen` |
| `vault` | `VaultScreen` |
| `skincare` | `PlaceholderScreen` (stub — no data model yet) |
| *anything else* | `PlaceholderScreen('Soon')` |

## Transitions

`_ScreenSwitcher` in `lib/app.dart` swaps screens with `PageTransitionSwitcher` (a ~50-line inlined clone of the `animations` package version — inlined to avoid a dependency). The transition is `_IosSwitchTransition`:

- Incoming screen: slides up from `Offset(0, 0.08)`, fades in, scales from 0.985 → 1.
- Outgoing screen: slides up to `Offset(0, -0.06)`, fades out.
- Duration: 340ms, `Curves.easeOutCubic` / `easeIn`.

If you change offsets, keep them vertical — the rest of the app (add-sheet, confirm-sheet, tweaks-sheet) all animate bottom-to-top.

## Overlays (not navigation)

Two UI affordances look like navigation but aren't:

- **TweaksSheet** (accent + dark toggle) — stacked over the shell with an opaque tap-catcher. Toggled by `AppShell._showTweaks`.
- **AddSheet** (bottom-sheet quick-add) — also stacked. Toggled by `AppShell._addOpen`. Each option calls `state.setScreen(key)` and closes the sheet; so "add" is actually "go to that screen."

These overlays don't push onto any navigator — Flutter's default back gesture doesn't dismiss them. If we ever need that, we'd wrap them in a `WillPopScope`.

## Adding a screen

See [contributing.md](contributing.md) — it's 3 edits: new file in `lib/screens/`, a `case` in `AppShell.build`, optionally an entry in `_placeholderLabel` (if you want the fallback to still work during development) and/or a row in `MoreScreen`.
