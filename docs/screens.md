# Screens

Each file in `lib/screens/` is a single top-level screen rendered by `AppShell`'s `switch`. This doc is an index — read each file for the widget details.

## Home — `home_screen.dart`

Landing page with three sections:

1. **Hero progress card** — gradient card with today's done/total task counts + animated ring (accent → accent2 gradient). Hardcoded to tasks; if tasks is empty it shows "Tap + in Tasks to add your first task."
2. **Finance quick stats** — two stat cards, owed-to-me (success color) and I-owe (danger color). Tap either → jumps to `finance`.
3. **Up next** — first three pending tasks (unchecked). Tap the checkbox to toggle.
4. **Coming up** — first event (or empty-state). Tap → `events`.

Why: this screen is the "one-tap status" surface, so every card jumps to the relevant domain.

## Tasks — `tasks_screen.dart`

Segmented tabs (Today / Upcoming / All) + two sections (Pending / Completed). Each row is `_DismissibleTask` — swipe-left shows the trash background, `confirmDismiss` pops the shared confirm sheet. Long-press opens edit.

`_TaskSheet` is the add/edit UI — title, time, category, icon (picker grid), color (palette). Icons are `AppIcons` keys to stay portable across Lucide upgrades.

## Finance — `finance_screen.dart`

Net-position gradient card (green when positive, danger when negative), followed by tabs (All / I owe / They owe) and a list of `_DebtCard` rows inside `Dismissible` swipe-to-delete. "Pay" opens `_openPaySheet` with quick-amount chips. Currency rendered from `state.profile.currencySymbol`.

## Events — `events_screen.dart`

Horizontal carousel of event cards, then budget summary (est vs. spent) and a checklist. Each `EventItem` is its own swipe-to-delete row with estimate + actual cost. Long-press on a checklist item opens `_openEditActualSheet` to log actual spend.

## Gym — `gym_screen.dart`

Weekly strip (M-T-W-T-F-S-S), exercises list for the selected day, bodyweight log with a simple line chart. Weight rows are swipe-to-delete with confirm. Exercises are swipe-to-delete; tap to edit.

## Snapshots — `snapshots_screen.dart`

Segmented cats (Hair / Body / Skin), grid of gradient tiles using the placeholder `hue`. Tap opens a fullscreen overlay. Long-press on a tile and tap on the overlay trash both go through `confirmDelete`. Add is a bottom sheet with a hue slider + note.

## More — `more_screen.dart`

The settings/index screen. Renders:

- Profile header card (tap → profile, Edit → profile).
- Sync-to-Claude card (the sync is a placeholder — writes a timestamp).
- Real-data row summaries under **Trackers / Health / Memory / Account**. Each sub-text is computed from state (no dummies).
- **Backup** section with `Export data` and `Import data` rows (see [backup.md](backup.md)).

## Profile — `profile_screen.dart`

Read-only view of the profile (name / DOB + age / phone) and an edit sheet. The edit sheet has:

- Name text field.
- Date-of-birth picker (native `showDatePicker`).
- Phone (digits + `+-()` filter).
- **Currency symbol picker** — 5 chips (₹ $ € £ ¥) + custom text field (max 3 chars). Selection writes to `profile.currencySymbol`.

## Notes / Saved links / Vault — `notes_screen.dart`, `links_screen.dart`, `vault_screen.dart`

All three share the same shape:

- List of swipe-to-delete rows (with `confirmDismiss`).
- Tap the row = primary action (open detail / edit / visit URL).
- Header `+` opens an add sheet; edit reuses the same sheet.

Vault has a **detail bottom sheet** with masked password, eye-toggle reveal, and copy-to-clipboard icons next to username and password (via `Clipboard.setData`).

Links normalise scheme-less input (`example.com` → `https://example.com`) at tap time via `_normalizeUrl`, then call `launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)`.

## Placeholder — `placeholder_screen.dart`

Fallback for any screen key the `switch` doesn't recognise. Currently routed to only by `skincare`. When you build out skincare, remove the case from `_placeholderLabel` in `app.dart`.

## The screen-level conventions

- Every screen returns a `ListView` (not `Scaffold` — `AppShell` owns the Scaffold).
- Bottom padding is `120` to leave room for the floating bottom nav.
- Header is always `AppHeader(theme: theme, greeting: Greeting(sub, title), right: [HeaderBtn…])`.
- Empty state goes in an `AppCard` with a Lucide icon + short copy + a CTA.
