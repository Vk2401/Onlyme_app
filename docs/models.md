# Models

All model files live in `lib/models/`. Each one is an immutable value type with `copyWith`, `toJson`, and `fromJson`. There is no build-time codegen; everything is hand-written.

## Conventions

- Every model has an `int id` (milliseconds-since-epoch) where multiple can exist.
- Every model has an `int createdAt` for time-ordered rendering where relevant.
- Optional fields are typed `String?`. `copyWith` supports `clearX: true` to explicitly null them out.
- `Color` is serialised as `color.value` (ARGB int) and restored with `Color(j['x'] as int)`.

## Reference

### `TaskItem` — `lib/models/task.dart`
One actionable task with category + streak metadata.

| Field | Purpose |
|---|---|
| `id` | Stable identity (ms-since-epoch) |
| `title`, `time`, `cat` | Display strings |
| `icon` | Key into `AppIcons.byKey()` — JSON-portable across icon lib upgrades |
| `color` | Accent for the card header |
| `done` | Completion flag |
| `streak` | Consecutive-day counter (not yet auto-incremented — roadmap) |
| `scheduledAt` | Optional `DateTime?` — when set, the notification service fires an OS reminder. See [notifications.md](notifications.md). |
| `isAlarm` | `false` = normal notification; `true` = alarm-clock mode (fires at alarm volume, bypasses silent). Default `false`. |

`time` is a free-text display string. `scheduledAt` is the source of truth for when the reminder fires.

### `Debt` — `lib/models/debt.dart`
One owed-money record, either direction.

| Field | Purpose |
|---|---|
| `id`, `person`, `note`, `due` | Metadata |
| `type` | `DebtType.iOwe` / `theyOwe` |
| `total`, `paid` | Amounts; `remain = total - paid`, computed |
| `settled` | Auto-flips to `true` when `paid >= total` via `AppState.payDebt` |

### `PlannedEvent` + `EventItem` — `lib/models/event.dart`
Events carry a checklist of budget items.

| Field | Purpose |
|---|---|
| `PlannedEvent.id`, `title`, `date`, `daysAway`, `icon`, `color` | Card metadata |
| `PlannedEvent.scheduledAt` | Optional `DateTime?` — when set, schedules two notifications (day-before + at-time). See [notifications.md](notifications.md). |
| `PlannedEvent.isAlarm` | `false` = normal; `true` = alarm-clock mode for the at-time notification. Default `false`. |
| `items` | `List<EventItem>` — the checklist |
| `EventItem.est` / `actual` | Planned vs. actual spend (int, base units of the chosen currency) |
| `EventItem.done` | Ticked checkbox |

Derived getters: `totalEst`, `totalActual`, `doneCount`.

### `GymPlan` / `GymDay` / `Exercise` — `lib/models/gym.dart`
A single seven-day plan.

| Type | Fields |
|---|---|
| `GymPlan` | `name`, `days` (length 7) |
| `GymDay` | `id`, `short` (M/T/W…), `label` (Push/Pull/Rest…), `today` flag (reserved), `done`, `isRest`, `exercises` |
| `Exercise` | `name`, `sets`, `reps`, `weight`, `done` |

### `Snapshot` — `lib/models/snapshot.dart`
Photo-journal entry. Supports both real images and gradient placeholders.

| Field | Purpose |
|---|---|
| `id`, `date`, `note` | Display |
| `hue` | HSL hue (0–359) used to colour the placeholder tile when no image is attached |
| `imagePath` | Nullable path to a saved image in app internal storage (`<documents>/snapshots/`). When set, the full image is shown instead of the gradient. |

Images are saved by the app to the internal documents directory; they are never written to the gallery. `imagePath` is stripped from the JSON before export and replaced with inline base64 `imageData` so the image travels with the backup.

### `WeightEntry` — `lib/models/weight_entry.dart`

| Field | Purpose |
|---|---|
| `timestamp` | ms-since-epoch, also the identity |
| `kg` | Weight in kilograms |
| `dateStr` | Pre-formatted "MMM d" — rendered directly |

### `Profile` — `lib/models/profile.dart`
Single-user profile. All fields optional except `createdAt`.

| Field | Purpose |
|---|---|
| `name`, `dob`, `phone` | Display fields |
| `createdAt` | Persisted on first launch — powers "Since …" in More |
| `currencySymbol` | Default `'₹'`. Used everywhere currency is rendered. |
| `alarmSoundPath` | Nullable path to a custom alarm audio file (`<documents>/alarms/`). |
| `alarmSoundName` | Display name of the picked alarm file (shown in More → Alarm Sound). |

`copyWith` accepts `clearAlarmSound: true` to explicitly null out both alarm fields simultaneously.

Derived `age` getter (null if `dob` absent or unparseable).

### `Note` — `lib/models/note.dart`

| Field | Purpose |
|---|---|
| `id`, `title`, `body`, `createdAt` | Self-evident |

### `SavedLink` — `lib/models/saved_link.dart`
Bookmarked URL with a title.

| Field | Purpose |
|---|---|
| `id`, `title`, `url`, `createdAt` | Self-evident |

Tapping a row opens `url` in the external browser (`url_launcher`, `LaunchMode.externalApplication`). Scheme-less strings get auto-prefixed with `https://` at tap time.

### `VaultEntry` — `lib/models/vault_entry.dart`
Password manager entry.

| Field | Purpose |
|---|---|
| `id`, `title`, `createdAt` | Self-evident |
| `username`, `url`, `note` | Optional |
| `password` | Required |

**Security note:** Stored as plain JSON in SharedPreferences. No device-level encryption. Data never leaves the device, but is not hardened against on-device attackers. If you add sync, **encrypt before writing**.

### `Expense` — `lib/models/expense.dart`
Single expense entry for the daily expense tracker.

| Field | Purpose |
|---|---|
| `id` | Stable identity (ms-since-epoch) |
| `amount` | Amount in base currency units (integer, no decimals) |
| `category` | One of `kExpenseCategories` (Food / Transport / Shopping / Entertainment / Health / Bills / Education / Other) |
| `note` | Optional description |
| `dateStr` | Pre-formatted "MMM d" — rendered directly |
| `timestamp` | ms-since-epoch for ordering |

`kExpenseCategories` is a top-level constant in the same file.

## Adding a model

See [contributing.md](contributing.md) for the step-by-step. Short version: copy `note.dart` as a template, add a storage key + read/write pair in `local_storage.dart`, add field + CRUD methods to `AppState`, and you're done with the data layer.
