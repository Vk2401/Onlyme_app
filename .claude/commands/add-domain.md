---
description: Scaffold a new OnlyMe domain (model, storage keys, AppState CRUD, screen, routing, backup)
argument-hint: <domain-name> (singular, e.g. "habit" or "recipe")
allowed-tools: Read, Edit, Write, Bash
---

Scaffold a new domain in the OnlyMe codebase named `$1` (passed as the first argument; fall back to asking the user if empty).

Generate all six pieces in one pass, following the existing conventions. Do NOT invent fields that weren't requested — default to `{id, title, note, createdAt}` and ask the user what else they need before writing anything more opinionated.

Required edits, in this order:

1. **Model** — `lib/models/$1.dart`. Copy the shape of `lib/models/note.dart` (immutable, `copyWith`, `toJson`, `fromJson`, ms-since-epoch `id` + `createdAt`).
2. **Storage** — `lib/storage/local_storage.dart`. Add `_k<Thing>s = 'onlyme:$1s'` + `read<Thing>s()` / `write<Thing>s(List)` methods. Use the same `jsonEncode/decode` pattern as `readNotes`.
3. **AppState** — `lib/app_state.dart`. Add import, `late List<Thing> <thing>s;`, initialise in `AppState.load()` with `?? []`, add `add / edit / delete` mutators following the three-line pattern (update list, persist, `notifyListeners()`), and add a read+assign line inside `reloadFromStorage()`.
4. **Screen** — `lib/screens/$1_screen.dart`. Copy `lib/screens/notes_screen.dart`'s skeleton: `ListView` root, `AppHeader` with `+` button, empty-state `AppCard`, swipe-to-delete rows wrapped in `confirmDismiss: (_) => confirmDelete(...)`, add/edit sheet.
5. **Routing** — in `lib/app.dart`: import the new screen, add `case '$1': content = const <Thing>Screen(); break;` inside `AppShell.build`, remove `'$1'` from `_placeholderLabel` if it was there.
6. **More screen** — `lib/screens/more_screen.dart`. Add an `_Item('$1', '<Label>', <real-count-sub>, '<icon>', <color>)` to the appropriate section. Sub text must come from `state.<thing>s` — no dummies.
7. **Quick-add** — `lib/widgets/add_sheet.dart`. Add an option so the `+` sheet can jump to the new screen.
8. **Backup** — `lib/storage/export_io.dart`. Add the domain to `exportAll`'s `data` map AND to `importAll`'s decode branches. Both updates or neither.
9. **Docs** — add one row to `docs/models.md` summarising the new type.

After editing, run `flutter analyze` and report any new issues.

Do NOT create a feature flag, do NOT add a migration, do NOT add tests unless the user asked. Keep each file under ~300 lines and match the existing spacing/style.
