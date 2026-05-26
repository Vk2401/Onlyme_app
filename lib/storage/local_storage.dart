import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/debt.dart';
import '../models/event.dart';
import '../models/gym.dart';
import '../models/snapshot.dart';
import '../models/weight_entry.dart';
import '../models/profile.dart';
import '../models/note.dart';
import '../models/saved_link.dart';
import '../models/vault_entry.dart';
import '../models/expense.dart';

class LocalStorage {
  static const _kTasks = 'onlyme:tasks';
  static const _kDebts = 'onlyme:debts';
  static const _kEvents = 'onlyme:events';
  static const _kGym = 'onlyme:gym';
  static const _kScreen = 'onlyme:screen';
  static const _kAccent = 'onlyme:accent';
  static const _kDark = 'onlyme:dark';
  static const _kLastSync = 'onlyme:lastSync';
  static const _kSnapshots = 'onlyme:snapshots';
  static const _kWeight = 'onlyme:weight';
  static const _kProfile = 'onlyme:profile';
  static const _kNotes = 'onlyme:notes';
  static const _kLinks = 'onlyme:links';
  static const _kVault = 'onlyme:vault';
  static const _kExpenses = 'onlyme:expenses';
  static const _kGymLastResetWeek   = 'onlyme:gym:lastResetWeek';
  static const _kGymLastResetDay    = 'onlyme:gym:lastResetDay';
  static const _kTasksLastResetDay  = 'onlyme:tasks:lastResetDay';

  final SharedPreferences _p;
  LocalStorage(this._p);

  static Future<LocalStorage> open() async {
    return LocalStorage(await SharedPreferences.getInstance());
  }

  // --- Tasks ---
  List<TaskItem>? readTasks() {
    final raw = _p.getString(_kTasks);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeTasks(List<TaskItem> tasks) =>
      _p.setString(_kTasks, jsonEncode(tasks.map((t) => t.toJson()).toList()));

  // --- Debts ---
  List<Debt>? readDebts() {
    final raw = _p.getString(_kDebts);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Debt.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeDebts(List<Debt> debts) =>
      _p.setString(_kDebts, jsonEncode(debts.map((t) => t.toJson()).toList()));

  // --- Events ---
  List<PlannedEvent>? readEvents() {
    final raw = _p.getString(_kEvents);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => PlannedEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeEvents(List<PlannedEvent> events) =>
      _p.setString(_kEvents, jsonEncode(events.map((t) => t.toJson()).toList()));

  // --- Gym ---
  GymPlan? readGym() {
    final raw = _p.getString(_kGym);
    if (raw == null) return null;
    return GymPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeGym(GymPlan plan) => _p.setString(_kGym, jsonEncode(plan.toJson()));

  // --- Snapshots ---
  Map<String, List<Snapshot>>? readSnapshots() {
    final raw = _p.getString(_kSnapshots);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(
          k,
          (v as List).map((e) => Snapshot.fromJson(e as Map<String, dynamic>)).toList(),
        ));
  }

  Future<void> writeSnapshots(Map<String, List<Snapshot>> snaps) =>
      _p.setString(
        _kSnapshots,
        jsonEncode(snaps.map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()))),
      );

  // --- Weight log ---
  List<WeightEntry>? readWeightLogs() {
    final raw = _p.getString(_kWeight);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => WeightEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeWeightLogs(List<WeightEntry> logs) =>
      _p.setString(_kWeight, jsonEncode(logs.map((e) => e.toJson()).toList()));

  // --- Screen ---
  String? readScreen() => _p.getString(_kScreen);
  Future<void> writeScreen(String s) => _p.setString(_kScreen, s);

  // --- Tweaks ---
  String? readAccent() => _p.getString(_kAccent);
  Future<void> writeAccent(String s) => _p.setString(_kAccent, s);

  bool? readDark() => _p.getBool(_kDark);
  Future<void> writeDark(bool b) => _p.setBool(_kDark, b);

  // --- Sync stamp ---
  String? readLastSync() => _p.getString(_kLastSync);
  Future<void> writeLastSync(String iso) => _p.setString(_kLastSync, iso);

  // --- Profile ---
  Profile? readProfile() {
    final raw = _p.getString(_kProfile);
    if (raw == null) return null;
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeProfile(Profile p) =>
      _p.setString(_kProfile, jsonEncode(p.toJson()));

  // --- Notes ---
  List<Note>? readNotes() {
    final raw = _p.getString(_kNotes);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeNotes(List<Note> notes) =>
      _p.setString(_kNotes, jsonEncode(notes.map((n) => n.toJson()).toList()));

  // --- Saved links ---
  List<SavedLink>? readLinks() {
    final raw = _p.getString(_kLinks);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavedLink.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeLinks(List<SavedLink> links) =>
      _p.setString(_kLinks, jsonEncode(links.map((l) => l.toJson()).toList()));

  // --- Vault ---
  List<VaultEntry>? readVault() {
    final raw = _p.getString(_kVault);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => VaultEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeVault(List<VaultEntry> entries) =>
      _p.setString(_kVault, jsonEncode(entries.map((v) => v.toJson()).toList()));

  // --- Expenses ---
  List<Expense>? readExpenses() {
    final raw = _p.getString(_kExpenses);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeExpenses(List<Expense> expenses) =>
      _p.setString(_kExpenses, jsonEncode(expenses.map((e) => e.toJson()).toList()));

  // --- Gym weekly reset ---
  String? readGymLastResetWeek() => _p.getString(_kGymLastResetWeek);
  Future<void> writeGymLastResetWeek(String key) => _p.setString(_kGymLastResetWeek, key);
  String? readGymLastResetDay() => _p.getString(_kGymLastResetDay);
  Future<void> writeGymLastResetDay(String key) => _p.setString(_kGymLastResetDay, key);

  // --- Tasks daily reset ---
  String? readTasksLastResetDay() => _p.getString(_kTasksLastResetDay);
  Future<void> writeTasksLastResetDay(String key) => _p.setString(_kTasksLastResetDay, key);
}
