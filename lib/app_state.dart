import 'package:flutter/foundation.dart';
import 'models/task.dart';
import 'models/debt.dart';
import 'models/event.dart';
import 'models/gym.dart';
import 'storage/local_storage.dart';
import 'data/seed_data.dart';
import 'theme/app_theme.dart';

class AppState extends ChangeNotifier {
  final LocalStorage storage;

  late List<TaskItem> tasks;
  late List<Debt> debts;
  late List<PlannedEvent> events;
  late GymPlan gym;

  String screen = 'home';
  AppTheme theme = AppTheme.build(dark: true, accentKey: AccentKey.mint);

  DateTime? lastSyncAt;

  AppState._(this.storage);

  static Future<AppState> load() async {
    final s = await LocalStorage.open();
    final state = AppState._(s);
    state.tasks = s.readTasks() ?? List<TaskItem>.from(seedTasks);
    state.debts = s.readDebts() ?? List<Debt>.from(seedDebts);
    state.events = s.readEvents() ?? List<PlannedEvent>.from(seedEvents);
    state.gym = s.readGym() ?? seedGymPlan;
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

  // --- Tasks ---
  void toggleTask(int id) {
    tasks = tasks.map((t) => t.id == id ? t.copyWith(done: !t.done) : t).toList();
    storage.writeTasks(tasks);
    notifyListeners();
  }

  // --- Debts ---
  void payDebt(int id, int amount) {
    debts = debts.map((d) {
      if (d.id != id) return d;
      final paid = (d.paid + amount).clamp(0, d.total);
      return d.copyWith(paid: paid, settled: paid >= d.total);
    }).toList();
    storage.writeDebts(debts);
    notifyListeners();
  }

  // --- Events ---
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

  // --- Gym ---
  void toggleExercise(int dayId, int exIndex) {
    gym = gym.copyWith(
      days: gym.days.map((day) {
        if (day.id != dayId) return day;
        final updated = <Exercise>[];
        for (var i = 0; i < day.exercises.length; i++) {
          updated.add(i == exIndex
              ? day.exercises[i].copyWith(done: !day.exercises[i].done)
              : day.exercises[i]);
        }
        return day.copyWith(exercises: updated);
      }).toList(),
    );
    storage.writeGym(gym);
    notifyListeners();
  }

  // --- Sync placeholder ---
  Future<void> syncNow() async {
    await Future.delayed(const Duration(milliseconds: 700));
    lastSyncAt = DateTime.now();
    await storage.writeLastSync(lastSyncAt!.toIso8601String());
    notifyListeners();
  }
}
