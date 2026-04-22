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
| `id` | Stable identity |
| `title`, `time`, `cat` | Display strings |
| `icon` | Key into `AppIcons.byKey()` — so JSON is portable across icon lib upgrades |
| `color` | Accent for the card header |
| `done` | Completion flag |
| `streak` | Consecutive-day counter (not yet auto-incremented — roadmap) |
| `scheduledAt` | Optional `DateTime?` used by the notifications service to fire an OS reminder. See [notifications.md](notifications.md). `time` is a free-text display string — `scheduledAt` is the source of truth for when the reminder fires. |

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
| `items` | `List<EventItem>` — the checklist |
| `EventItem.est` / `actual` | Planned vs. actual spend (int, base units of the chosen currency) |
| `EventItem.done` | Ticked checkbox |

Derived getters: `totalEst`, `totalActual`, `doneCount`.

### `GymPlan` / `GymDay` / `Exercise` — `lib/models/gym.dart`
A single seven-day plan.

| Type | Fields |
|---|---|
| `GymPlan` | `name`, `days` (length 7) |
| `GymDay` | `id`, `short` (M/T/W…), `label` (Push/Pull/Rest…), `today` flag (reserved), `done`, `exercises` |
| `Exercise` | `name`, `sets`, `reps`, `weight`, `done` |

### `Snapshot` — `lib/models/snapshot.dart`
Photo-journal placeholder. Real images aren't stored yet; the UI renders a gradient using `hue` as a stand-in.

| Field | Purpose |
|---|---|
| `id`, `date`, `note` | Display |
| `hue` | HSL hue (0–359) used to colour the placeholder tile |

**Roadmap:** replace `hue` with a file path once image capture is added; JSON will gain an optional `imagePath` field.

### `WeightEntry` — `lib/models/weight_entry.dart`
| Field | Purpose |
|---|---|
| `timestamp` | ms-since-epoch, also the identity |
| `kg` | Weight in kilograms |
| `dateStr` | Pre-formatted "MMM d" — rendered directly |

### `Profile` — `lib/models/profile.dart`
Single-user profile. All fields optional.

| Field | Purpose |
|---|---|
| `name`, `dob`, `phone` | Display |
| `createdAt` | Persisted on first launch — powers "Since …" in More |
| `currencySymbol` | Default `'₹'`. Used in place of every hard-coded currency string. |

Derived `age` getter (null if `dob` absent or unparseable).

### `Note` — `lib/models/note.dart`
Simple note.

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

**Security note:** Stored as plain JSON in SharedPreferences. No device-level encryption. The app is "local-only" in the sense that data never leaves the device, not "hardened against on-device attackers." If you plan to sync, **encrypt before writing** (and document the KDF somewhere other than this repo).

## Adding a model

See [contributing.md](contributing.md) for the step-by-step. Short version: copy `note.dart` as a template, add a storage key + read/write pair in `local_storage.dart`, add field + CRUD methods to `AppState`, and you're done with the data layer.
