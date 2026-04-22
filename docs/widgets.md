# Shared widgets

Reusable UI in `lib/widgets/`. Each widget takes an explicit `theme: AppTheme` (or reads it from `AppState` if it's a standalone overlay).

## Primitives — `primitives.dart`

| Widget | Purpose |
|---|---|
| `AppCard` | Rounded (18px) container with `theme.surface` fill + `theme.rule` border. Optional `onTap` wraps it in an `InkWell`. The single source of truth for "card" in this app. |
| `IconChip` | Coloured rounded square (12px radius) for icon tiles. Used as the leading glyph on most rows. |
| `Ring` | Animated arc progress indicator (used on Home hero card). Paints a track circle + a coloured arc that tweens on value change. |
| `CheckBubble` | iOS-style round checkbox with scale-in checkmark animation. |
| `SectionHead` | Row with a bold title + optional right-aligned action ("See all"). |

## Confirm sheet — `confirm_sheet.dart`

`Future<bool> confirmDelete(ctx, {title, message, confirmLabel, icon})` — the single entry point for every destructive action in the app. Styled as a bottom sheet with a danger icon chip, Cancel + Delete buttons. Returns `true` iff the user tapped the confirm button.

**Usage pattern for `Dismissible`:**

```dart
Dismissible(
  key: …,
  direction: DismissDirection.endToStart,
  background: …,
  confirmDismiss: (_) => confirmDelete(context, title: '…', message: '…'),
  onDismissed: (_) => context.read<AppState>().deleteX(id),
  child: …,
);
```

**Usage pattern for menu/button deletes:**

```dart
onTap: () async {
  final ok = await confirmDelete(context, title: '…');
  if (!ok || !context.mounted) return;
  context.read<AppState>().deleteX(id);
},
```

If you're adding a new delete path, use this helper. Don't roll your own dialog.

## Header — `header.dart`

`AppHeader({theme, greeting: Greeting(sub, title), right: [HeaderBtn…]})` — the 60ish-pixel header every screen uses. `HeaderBtn` is a tappable 42×42 rounded square with an icon, optional badge dot.

## Bottom nav — `bottom_nav.dart`

Floating translucent tab bar with a bulging `+` button in the middle. Tabs are `home / tasks / add / events / more`. `add` opens `AddSheet`; the rest call `state.setScreen(key)`.

## Add sheet — `add_sheet.dart`

Bottom sheet with an 8-item grid: Task, Debt, Event, Workout, Snapshot, Note, Link, Password. Each option jumps to its screen and closes the sheet. Not a form — just navigation.

## Tweaks sheet — `tweaks_sheet.dart`

Opened from the ⚙ button on More. Lets the user pick accent (`AccentKey` chips) and dark/light. Writes to `AppState` immediately.

## Task card — `task_card.dart`

The row used by both the Home "Up next" section and the Tasks list's primary render. Extracted so the animation on toggle is consistent everywhere.

## Icons — `app_icons.dart`

`AppIcons.byKey(String)` maps stable keys (`checkCircle`, `dumbbell`, …) to `LucideIcons` values. The indirection matters because:

1. JSON payloads (stored, exported, imported) embed the key, not the `IconData`.
2. If we ever swap icon libraries, only this file changes.

If you add an icon to a form picker or seed entry, register it here.

## Segmented — `segmented.dart`

Generic pill-shaped tab control. Parametrised by a value type `T` — used by Finance (`'all' / 'i_owe' / 'they_owe'`), Snapshots (`'hair' / 'body' / 'skin'`), etc.

## Status bar — `status_bar.dart`

Small iOS-style status strip rendered inside some of the hero cards. Purely cosmetic.
