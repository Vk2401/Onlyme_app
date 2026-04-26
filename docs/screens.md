# Screens

Each file in `lib/screens/` is a single top-level screen rendered by `AppShell`'s `switch`. This doc is an index — read each file for the widget details.

## Home — `home_screen.dart`

Landing page with four sections:

1. **Hero progress card** — gradient card with today's done/total task counts + animated ring (accent → accent2 gradient). Shows "Tap + in Tasks" empty state when task list is empty.
2. **Finance quick stats** — two stat cards: owed-to-me (success color) and I-owe (danger color). Tap either → jumps to `finance`.
3. **Up next** — first three pending tasks (unchecked). Tap the checkbox to toggle.
4. **Coming up** — first event or empty-state. Tap → `events`.

## Tasks — `tasks_screen.dart`

Segmented tabs (Today / Upcoming / All) + two sections (Pending / Completed). Each row is `_DismissibleTask` — swipe-left shows the trash background, `confirmDismiss` pops the shared confirm sheet. Long-press opens edit.

**`_TaskSheet`** is the add/edit UI:
- Title, time, category, icon picker, color palette.
- **Reminder row** — taps open a date+time picker. Displays "No reminder" when unset, formatted datetime when set. Clearing the time also clears alarm mode.
- **Alarm mode toggle** (`_AlarmToggleRow`) — animated pill switch, shown only when a reminder is set. Off = normal notification; On = alarm-clock mode (bypasses silent, fires at alarm volume). See [notifications.md](notifications.md).

## Finance — `finance_screen.dart`

Net-position gradient card (green when positive, danger when negative), followed by tabs (All / I owe / They owe) and a list of `_DebtCard` rows inside `Dismissible` swipe-to-delete. "Pay" opens `_openPaySheet` with quick-amount chips. Currency rendered from `state.profile.currencySymbol`.

## Events — `events_screen.dart`

Horizontal carousel of event cards, then budget summary (est vs. spent) and a checklist. Each `EventItem` is its own swipe-to-delete row with estimate + actual cost. Long-press opens `_openEditActualSheet` to log actual spend.

**`_EventSheet`** add/edit UI mirrors the Task sheet:
- Title, date, days-away, icon, color.
- **Reminder row** — date+time picker. Clearing resets alarm mode.
- **Alarm mode toggle** (`_EventAlarmToggle`) — same design as the task toggle. Only visible when a reminder date is set.

## Gym — `gym_screen.dart`

Weekly strip (M-T-W-T-F-S-S), exercises list for the selected day, body-weight log with a simple line chart. Weight rows are swipe-to-delete with confirm. Exercises are swipe-to-delete; tap to edit inline.

## Snapshots — `snapshots_screen.dart`

Segmented cats (Hair / Body / Skin), grid of tiles. When a snapshot has an `imagePath`, the real image is displayed; otherwise a gradient using `hue` is shown. Tap opens a full-screen overlay. Long-press on a tile and the overlay trash both go through `confirmDelete`. Add is a bottom sheet with image capture, a hue slider, and a note.

## Expenses — `expenses_screen.dart`

Daily expense tracker.

- **Summary card** — today's total spend and entry count.
- **Category breakdown** — horizontal chip strip; tap a chip to filter.
- **Entry list** — sorted by timestamp descending. Swipe-to-delete with `confirmDismiss`. Tap to edit.
- **Add sheet** — amount (numpad), category picker, note field.

Currency symbol from `state.profile.currencySymbol`. Categories from `kExpenseCategories` in `expense.dart`.

## More — `more_screen.dart`

Settings and index screen:

- **Profile header card** — tap → profile, Edit → profile edit sheet.
- **Sync card** — placeholder; writes a timestamp only.
- **Domain summaries** under Trackers / Health / Memory / Account — real counts/data computed from state.
- **Backup section** — Export and Import rows. See [backup.md](backup.md).
- **Notifications section** (`_NotificationsSection`) — three real-time permission rows:
  - POST_NOTIFICATIONS — "Grant" button calls `requestPermission()`.
  - Exact alarms — "Open settings" navigates to "Alarms & reminders" special-access. Status refreshes on app resume via `WidgetsBindingObserver`.
  - Battery unrestricted — "Open settings" opens battery optimisation page.
  - "Send test notification" button — schedules a notification 10 s out, shows result inline.
- **Alarm Sound row** (`_AlarmSoundRow`) — file picker for any audio file; copies to `<documents>/alarms/`; stores path + name in `Profile`.

## Profile — `profile_screen.dart`

Read-only view (name / DOB + age / phone) and an edit sheet:

- Name text field.
- Date-of-birth picker (`showDatePicker`).
- Phone field (digits + `+-()` filter).
- **Currency symbol picker** — 5 chips (₹ $ € £ ¥) + custom text field (max 3 chars). Writes to `profile.currencySymbol`.

## Notes — `notes_screen.dart`

List of swipe-to-delete rows (`confirmDismiss`). Tap → edit sheet. Header `+` → add sheet.

## Saved Links — `links_screen.dart`

Same shape as Notes. Tap row → opens URL in external browser via `url_launcher`. Scheme-less input auto-prefixed with `https://` at tap time.

## Vault — `vault_screen.dart`

Password manager. Same list shape, plus:

- **Detail bottom sheet** — masked password, eye-toggle reveal, copy-to-clipboard next to username + password.
- Long-press row → edit sheet.

## Placeholder — `placeholder_screen.dart`

Fallback for unrecognised screen keys. Currently rendered only for `skincare`. Remove when skincare is built out.

## App shell conventions (`lib/app.dart`)

- **`AppShell`** owns the single `Scaffold`. Screens return a `ListView`, not `Scaffold`.
- **`PopScope(canPop: false)`** wraps the Scaffold. Back-press layers:
  1. Dismiss tweaks overlay if open.
  2. Dismiss add sheet if open.
  3. Navigate to `home` if on a sub-screen.
  4. Show "Exit app?" confirm sheet; if confirmed, calls `SystemNavigator.pop()`.
- Bottom padding on every screen is `120` to clear the floating bottom nav.
- Header is always `AppHeader(theme: theme, greeting: Greeting(sub, title), right: [...])`.
- Empty state goes in an `AppCard` with a Lucide icon + short copy + CTA.
