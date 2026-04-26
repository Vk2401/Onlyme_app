# Contributing to Only Me

Thank you for your interest in contributing to Only Me. This document explains how to get set up, what to know before opening a PR, and the conventions the codebase follows.

---

## Getting started

```bash
# Clone the repo
git clone https://github.com/vk2401/onlyme_app.git
cd onlyme_app

# Install Flutter dependencies
flutter pub get

# Run on a connected device or simulator
flutter run

# Lint
flutter analyze

# Tests
flutter test
```

Requirements: Flutter ≥ 3.19.0, Dart ≥ 3.3.0. Android target SDK ≥ 34.

---

## Project structure

```
lib/
  models/        Pure Dart value types (toJson / fromJson / copyWith)
  storage/       LocalStorage wrapper + export/import logic
  services/      NotificationsService singleton
  theme/         AppTheme value object + accent enum
  widgets/       Reusable UI primitives
  screens/       One file per top-level screen
  app_state.dart Single ChangeNotifier — all domain state + mutations
  app.dart       MaterialApp, AppShell, screen switch, transitions
  main.dart      Bootstrap
```

Full architecture: [docs/architecture.md](docs/architecture.md)

---

## Before you open a PR

1. **Run `flutter analyze`** — should report zero issues (or only the pre-existing infos listed in [docs/ci.md](docs/ci.md)).
2. **Test the change on a real device or emulator** end-to-end.
3. **Keep the PR focused** — one feature or one fix per PR.
4. **Follow the conventions below** — the reviewer will flag any violations.

---

## Conventions

### State mutations

Every mutation in `AppState` must:
- Replace lists immutably (use spread / `where` / `map`).
- Call `storage.writeX(...)` **before** `notifyListeners()`.
- Never call `NotificationsService` from the UI — only from AppState mutators.

### Destructive actions

Every delete or overwrite **must** go through `confirmDelete()` from `lib/widgets/confirm_sheet.dart`. No raw `state.deleteX()` calls directly from tap handlers.

```dart
// Correct
confirmDismiss: (_) => confirmDelete(context, title: 'Delete task?', message: '...'),
onDismissed: (_) => context.read<AppState>().deleteTask(id),

// Wrong
onTap: () => context.read<AppState>().deleteTask(id),
```

### Currency

Never hard-code `₹`, `$`, or any currency symbol. Read `state.profile.currencySymbol` at the render site.

```dart
Text('${state.profile.currencySymbol}${amount}')  // correct
Text('₹${amount}')                                 // wrong
```

### Theme colours

Do not use `Theme.of(context)` for app colours. Pass `AppTheme` explicitly.

```dart
AppCard(theme: theme, ...)    // correct
Container(color: Theme.of(context).colorScheme.surface)  // wrong
```

### Background colour

`theme.bg` is painted in exactly **one** place — the outer `Container` in `AppShell.build`. Do not add a second `Container(color: theme.bg)` inside screens or widgets — it causes a flicker during the theme-toggle transition.

### Screen transitions

All transitions animate **bottom-to-top**. Don't add horizontal slides or fades in the opposite direction.

### Comments

Write no comments for code that is self-explanatory by its name. Write a comment only when the *why* would surprise a future reader (a hidden constraint, a workaround for a specific bug, a non-obvious invariant).

---

## Adding a new domain

A full walkthrough is in [docs/contributing.md](docs/contributing.md). The six edits:

1. `lib/models/your_thing.dart` — value type with `copyWith / toJson / fromJson`.
2. `lib/storage/local_storage.dart` — add `onlyme:thing` key + `readThing / writeThing`.
3. `lib/app_state.dart` — add field, `addThing / editThing / deleteThing`, init in `load()` and `reloadFromStorage()`.
4. `lib/screens/your_thing_screen.dart` — `ListView` root, `AppHeader`, empty state, swipe-to-delete rows.
5. `lib/app.dart` — add `case 'thing':` to the screen switch.
6. `lib/storage/export_io.dart` — add to `exportAll` data map + a decode branch in `importAll`.

---

## Reporting bugs

Open a GitHub issue with:
- Flutter version (`flutter --version`).
- Device/emulator + Android version.
- Steps to reproduce.
- Expected vs. actual behaviour.
- Logs if relevant (`flutter run` output).

---

## Suggesting features

Open a GitHub issue tagged `enhancement`. Describe the use case, not just the solution. Small, focused features are much more likely to land quickly.

---

## Code of conduct

Be respectful. Constructive criticism is welcome; personal attacks are not. We reserve the right to close issues or PRs that are not constructive.

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE) that covers this project.
