import 'package:flutter/material.dart';
import 'models/task.dart';
import 'models/debt.dart';
import 'models/event.dart';
import 'models/gym.dart';
import 'models/snapshot.dart';
import 'models/weight_entry.dart';
import 'models/profile.dart';
import 'models/note.dart';
import 'models/saved_link.dart';
import 'models/vault_entry.dart';
import 'models/expense.dart';
import 'services/notifications_service.dart';
import 'storage/local_storage.dart';
import 'data/seed_data.dart';
import 'theme/app_theme.dart';

class AppState extends ChangeNotifier {
  final LocalStorage storage;

  late List<TaskItem> tasks;
  late List<Debt> debts;
  late List<PlannedEvent> events;
  late GymPlan gym;
  late Map<String, List<Snapshot>> snapshots;
  late List<WeightEntry> weightLogs;
  late Profile profile;
  late List<Note> notes;
  late List<SavedLink> links;
  late List<VaultEntry> vault;
  late List<Expense> expenses;

  String screen = 'home';
  AppTheme theme = AppTheme.build(dark: true, accentKey: AccentKey.mint);
  DateTime? lastSyncAt;

  AppState._(this.storage);

  static Future<AppState> load() async {
    final s = await LocalStorage.open();
    final state = AppState._(s);
    state.tasks = s.readTasks() ?? List.from(seedTasks);
    state.debts = s.readDebts() ?? List.from(seedDebts);
    state.events = s.readEvents() ?? List.from(seedEvents);
    state.gym = s.readGym() ?? seedGymPlan;
    state.snapshots = s.readSnapshots() ?? Map.from(seedSnapshots);
    state.weightLogs = s.readWeightLogs() ?? List.from(seedWeightLogs);
    state.profile = s.readProfile() ?? Profile(createdAt: DateTime.now().millisecondsSinceEpoch);
    if (s.readProfile() == null) {
      await s.writeProfile(state.profile);
    }
    state.notes = s.readNotes() ?? [];
    state.links = s.readLinks() ?? [];
    state.vault = s.readVault() ?? [];
    state.expenses = s.readExpenses() ?? [];
    state.screen = s.readScreen() ?? 'home';

    final ak = s.readAccent();
    final dk = s.readDark();
    final accent = AccentKey.values.firstWhere(
      (e) => e.name == ak,
      orElse: () => AccentKey.mint,
    );
    state.theme = AppTheme.build(dark: dk ?? true, accentKey: accent);

    final last = s.readLastSync();
    state.lastSyncAt = last == null ? null : DateTime.tryParse(last);
    return state;
  }

  /// Re-plan every task/event notification that is still in the future.
  /// Called from main() after NotificationsService.init() so a clean install
  /// (or first launch after an OS update that cleared pending alarms) restores
  /// every scheduled reminder.
  Future<void> replayScheduledNotifications() async {
    final svc = NotificationsService.instance;
    final now = DateTime.now();
    for (final t in tasks) {
      if (!t.done && t.scheduledAt != null && t.scheduledAt!.isAfter(now)) {
        await svc.scheduleTask(
          id: t.id,
          title: t.title,
          body: t.cat.isEmpty ? null : t.cat,
          at: t.scheduledAt!,
        );
      }
    }
    for (final e in events) {
      if (e.scheduledAt != null && e.scheduledAt!.isAfter(now)) {
        await svc.scheduleEvent(
          id: e.id,
          title: e.title,
          body: e.date,
          at: e.scheduledAt!,
        );
      }
    }
  }

  // --- Screen ---
  void setScreen(String s) {
    screen = s;
    storage.writeScreen(s);
    notifyListeners();
  }

  // --- Theme ---
  void setAccent(AccentKey a) {
    theme = theme.copyWith(accentKey: a);
    storage.writeAccent(a.name);
    notifyListeners();
  }

  void setDark(bool d) {
    theme = theme.copyWith(dark: d);
    storage.writeDark(d);
    notifyListeners();
  }

  // --- Tasks CRUD ---
  void addTask({
    required String title,
    required String time,
    required String cat,
    required String icon,
    required Color color,
    DateTime? scheduledAt,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch;
    final task = TaskItem(
      id: id, title: title, time: time, cat: cat, icon: icon, color: color,
      done: false, streak: 0, scheduledAt: scheduledAt,
    );
    tasks = [...tasks, task];
    storage.writeTasks(tasks);
    _rescheduleTask(task);
    notifyListeners();
  }

  void editTask(TaskItem updated) {
    tasks = tasks.map((t) => t.id == updated.id ? updated : t).toList();
    storage.writeTasks(tasks);
    _rescheduleTask(updated);
    notifyListeners();
  }

  void toggleTask(int id) {
    tasks = tasks.map((t) => t.id == id ? t.copyWith(done: !t.done) : t).toList();
    storage.writeTasks(tasks);
    // Completed tasks cancel their reminder; uncompleted re-activate.
    final t = tasks.firstWhere((t) => t.id == id);
    _rescheduleTask(t);
    notifyListeners();
  }

  void deleteTask(int id) {
    tasks = tasks.where((t) => t.id != id).toList();
    storage.writeTasks(tasks);
    NotificationsService.instance.cancelTask(id);
    notifyListeners();
  }

  void _rescheduleTask(TaskItem t) {
    final svc = NotificationsService.instance;
    if (t.done || t.scheduledAt == null) {
      svc.cancelTask(t.id);
      return;
    }
    svc.scheduleTask(
      id: t.id,
      title: t.title,
      body: t.cat.isEmpty ? null : t.cat,
      at: t.scheduledAt!,
    );
  }

  // --- Debts CRUD ---
  void addDebt({
    required String person,
    required DebtType type,
    required int total,
    required String due,
    required String note,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch;
    debts = [
      ...debts,
      Debt(id: id, person: person, type: type, total: total, paid: 0, due: due, note: note),
    ];
    storage.writeDebts(debts);
    notifyListeners();
  }

  void editDebt(Debt updated) {
    // Clamp paid to new total if total was reduced
    final clamped = updated.paid > updated.total
        ? updated.copyWith(paid: updated.total, settled: true)
        : updated;
    debts = debts.map((d) => d.id == clamped.id ? clamped : d).toList();
    storage.writeDebts(debts);
    notifyListeners();
  }

  void payDebt(int id, int amount) {
    debts = debts.map((d) {
      if (d.id != id) return d;
      final paid = (d.paid + amount).clamp(0, d.total);
      return d.copyWith(paid: paid, settled: paid >= d.total);
    }).toList();
    storage.writeDebts(debts);
    notifyListeners();
  }

  void deleteDebt(int id) {
    debts = debts.where((d) => d.id != id).toList();
    storage.writeDebts(debts);
    notifyListeners();
  }

  // --- Events CRUD ---
  void addEvent({
    required String title,
    required String date,
    required int daysAway,
    required String icon,
    required Color color,
    DateTime? scheduledAt,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch;
    final ev = PlannedEvent(
      id: id, title: title, date: date, daysAway: daysAway, icon: icon,
      color: color, items: [], scheduledAt: scheduledAt,
    );
    events = [...events, ev];
    storage.writeEvents(events);
    _rescheduleEvent(ev);
    notifyListeners();
  }

  void editEvent(PlannedEvent updated) {
    events = events.map((e) => e.id == updated.id ? updated : e).toList();
    storage.writeEvents(events);
    _rescheduleEvent(updated);
    notifyListeners();
  }

  void deleteEvent(int id) {
    events = events.where((e) => e.id != id).toList();
    storage.writeEvents(events);
    NotificationsService.instance.cancelEvent(id);
    notifyListeners();
  }

  void _rescheduleEvent(PlannedEvent e) {
    final svc = NotificationsService.instance;
    if (e.scheduledAt == null) {
      svc.cancelEvent(e.id);
      return;
    }
    svc.scheduleEvent(
      id: e.id,
      title: e.title,
      body: e.date,
      at: e.scheduledAt!,
    );
  }

  void toggleEventItem(int eventId, int itemId) {
    events = events.map((e) {
      if (e.id != eventId) return e;
      return e.copyWith(
        items: e.items.map((it) {
          if (it.id != itemId) return it;
          final nextDone = !it.done;
          return it.copyWith(
            done: nextDone,
            actual: nextDone && it.actual == 0 ? it.est : it.actual,
          );
        }).toList(),
      );
    }).toList();
    storage.writeEvents(events);
    notifyListeners();
  }

  void addEventItem(int eventId, {required String label, required int est}) {
    final itemId = DateTime.now().millisecondsSinceEpoch;
    events = events.map((e) {
      if (e.id != eventId) return e;
      return e.copyWith(items: [...e.items, EventItem(id: itemId, label: label, est: est, actual: 0, done: false)]);
    }).toList();
    storage.writeEvents(events);
    notifyListeners();
  }

  void editEventItem(int eventId, EventItem updated) {
    events = events.map((e) {
      if (e.id != eventId) return e;
      return e.copyWith(items: e.items.map((it) => it.id == updated.id ? updated : it).toList());
    }).toList();
    storage.writeEvents(events);
    notifyListeners();
  }

  void deleteEventItem(int eventId, int itemId) {
    events = events.map((e) {
      if (e.id != eventId) return e;
      return e.copyWith(items: e.items.where((it) => it.id != itemId).toList());
    }).toList();
    storage.writeEvents(events);
    notifyListeners();
  }

  // --- Gym CRUD ---
  void addExercise(int dayId, {required String name, required int sets, required String reps, required String weight}) {
    gym = gym.copyWith(
      days: gym.days.map((d) {
        if (d.id != dayId) return d;
        return d.copyWith(exercises: [...d.exercises, Exercise(name: name, sets: sets, reps: reps, weight: weight, done: false)]);
      }).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  void editExercise(int dayId, int exIndex, Exercise updated) {
    gym = gym.copyWith(
      days: gym.days.map((d) {
        if (d.id != dayId) return d;
        final exs = List<Exercise>.from(d.exercises);
        exs[exIndex] = updated;
        return d.copyWith(exercises: exs);
      }).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  void toggleExercise(int dayId, int exIndex) {
    gym = gym.copyWith(
      days: gym.days.map((day) {
        if (day.id != dayId) return day;
        final updated = <Exercise>[];
        for (var i = 0; i < day.exercises.length; i++) {
          updated.add(i == exIndex ? day.exercises[i].copyWith(done: !day.exercises[i].done) : day.exercises[i]);
        }
        return day.copyWith(exercises: updated);
      }).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  void deleteExercise(int dayId, int exIndex) {
    gym = gym.copyWith(
      days: gym.days.map((d) {
        if (d.id != dayId) return d;
        final exs = List<Exercise>.from(d.exercises)..removeAt(exIndex);
        return d.copyWith(exercises: exs);
      }).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  void editGymPlanName(String name) {
    gym = gym.copyWith(name: name);
    storage.writeGym(gym);
    notifyListeners();
  }

  void editGymDayLabel(int dayId, String label) {
    gym = gym.copyWith(
      days: gym.days.map((d) => d.id == dayId ? d.copyWith(label: label) : d).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  void markDayDone(int dayId, bool done) {
    gym = gym.copyWith(
      days: gym.days.map((d) => d.id == dayId ? d.copyWith(done: done) : d).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  // --- Snapshots CRUD ---
  void addSnapshot(String cat, {required String note, required int hue}) {
    final id = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    final dateStr = '${_monthAbbr(now.month)} ${now.day}';
    final snap = Snapshot(id: id, date: dateStr, note: note, hue: hue);
    snapshots = Map.from(snapshots)..[cat] = [snap, ...(snapshots[cat] ?? [])];
    storage.writeSnapshots(snapshots);
    notifyListeners();
  }

  void deleteSnapshot(String cat, int id) {
    snapshots = Map.from(snapshots)..[cat] = (snapshots[cat] ?? []).where((s) => s.id != id).toList();
    storage.writeSnapshots(snapshots);
    notifyListeners();
  }

  // --- Weight log ---
  void logWeight(double kg) {
    final now = DateTime.now();
    final entry = WeightEntry(
      timestamp: now.millisecondsSinceEpoch,
      kg: kg,
      dateStr: '${_monthAbbr(now.month)} ${now.day}',
    );
    weightLogs = [...weightLogs, entry];
    storage.writeWeightLogs(weightLogs);
    notifyListeners();
  }

  void deleteWeightLog(int timestamp) {
    weightLogs = weightLogs.where((w) => w.timestamp != timestamp).toList();
    storage.writeWeightLogs(weightLogs);
    notifyListeners();
  }

  // --- Profile ---
  void updateProfile({String? name, String? dob, String? phone, String? currencySymbol}) {
    profile = profile.copyWith(
      name: (name == null || name.trim().isEmpty) ? null : name.trim(),
      dob: (dob == null || dob.trim().isEmpty) ? null : dob.trim(),
      phone: (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
      clearName: name == null || name.trim().isEmpty,
      clearDob: dob == null || dob.trim().isEmpty,
      clearPhone: phone == null || phone.trim().isEmpty,
      currencySymbol: (currencySymbol == null || currencySymbol.trim().isEmpty)
          ? null
          : currencySymbol.trim(),
    );
    storage.writeProfile(profile);
    notifyListeners();
  }

  // --- Notes CRUD ---
  void addNote({required String title, required String body}) {
    final id = DateTime.now().millisecondsSinceEpoch;
    notes = [Note(id: id, title: title, body: body, createdAt: id), ...notes];
    storage.writeNotes(notes);
    notifyListeners();
  }

  void editNote(Note updated) {
    notes = notes.map((n) => n.id == updated.id ? updated : n).toList();
    storage.writeNotes(notes);
    notifyListeners();
  }

  void deleteNote(int id) {
    notes = notes.where((n) => n.id != id).toList();
    storage.writeNotes(notes);
    notifyListeners();
  }

  // --- Saved links CRUD ---
  void addLink({required String title, required String url}) {
    final id = DateTime.now().millisecondsSinceEpoch;
    links = [SavedLink(id: id, title: title, url: url, createdAt: id), ...links];
    storage.writeLinks(links);
    notifyListeners();
  }

  void editLink(SavedLink updated) {
    links = links.map((l) => l.id == updated.id ? updated : l).toList();
    storage.writeLinks(links);
    notifyListeners();
  }

  void deleteLink(int id) {
    links = links.where((l) => l.id != id).toList();
    storage.writeLinks(links);
    notifyListeners();
  }

  // --- Vault CRUD ---
  void addVaultEntry({
    required String title,
    String? username,
    required String password,
    String? url,
    String? note,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch;
    vault = [
      VaultEntry(
        id: id, title: title, username: username, password: password,
        url: url, note: note, createdAt: id,
      ),
      ...vault,
    ];
    storage.writeVault(vault);
    notifyListeners();
  }

  void editVaultEntry(VaultEntry updated) {
    vault = vault.map((v) => v.id == updated.id ? updated : v).toList();
    storage.writeVault(vault);
    notifyListeners();
  }

  void deleteVaultEntry(int id) {
    vault = vault.where((v) => v.id != id).toList();
    storage.writeVault(vault);
    notifyListeners();
  }

  // --- Expenses CRUD ---
  void addExpense({required int amount, required String category, required String note}) {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;
    final e = Expense(
      id: id, amount: amount, category: category, note: note,
      dateStr: '${_monthAbbr(now.month)} ${now.day}', timestamp: id,
    );
    expenses = [e, ...expenses];
    storage.writeExpenses(expenses);
    notifyListeners();
  }

  void editExpense(Expense updated) {
    expenses = expenses.map((e) => e.id == updated.id ? updated : e).toList();
    storage.writeExpenses(expenses);
    notifyListeners();
  }

  void deleteExpense(int id) {
    expenses = expenses.where((e) => e.id != id).toList();
    storage.writeExpenses(expenses);
    notifyListeners();
  }

  // --- Full reload (used by import) ---
  Future<void> reloadFromStorage() async {
    tasks = storage.readTasks() ?? [];
    debts = storage.readDebts() ?? [];
    events = storage.readEvents() ?? [];
    gym = storage.readGym() ?? gym;
    snapshots = storage.readSnapshots() ?? snapshots;
    weightLogs = storage.readWeightLogs() ?? [];
    profile = storage.readProfile() ?? profile;
    notes = storage.readNotes() ?? [];
    links = storage.readLinks() ?? [];
    vault = storage.readVault() ?? [];
    expenses = storage.readExpenses() ?? [];
    final ak = storage.readAccent();
    final dk = storage.readDark();
    final accent = AccentKey.values.firstWhere(
      (e) => e.name == ak,
      orElse: () => theme.accentKey,
    );
    theme = theme.copyWith(accentKey: accent, dark: dk ?? theme.dark);
    notifyListeners();
  }

  // --- Sync placeholder ---
  Future<void> syncNow() async {
    await Future.delayed(const Duration(milliseconds: 700));
    lastSyncAt = DateTime.now();
    await storage.writeLastSync(lastSyncAt!.toIso8601String());
    notifyListeners();
  }

  static String _monthAbbr(int month) {
    const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return abbrs[month - 1];
  }
}
