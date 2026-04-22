import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/debt.dart';
import '../models/event.dart';
import '../models/gym.dart';

class LocalStorage {
  static const _kTasks = 'onlyme:tasks';
  static const _kDebts = 'onlyme:debts';
  static const _kEvents = 'onlyme:events';
  static const _kGym = 'onlyme:gym';
  static const _kScreen = 'onlyme:screen';
  static const _kAccent = 'onlyme:accent';
  static const _kDark = 'onlyme:dark';
  static const _kLastSync = 'onlyme:lastSync';

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

  // --- Screen ---
  String? readScreen() => _p.getString(_kScreen);
  Future<void> writeScreen(String s) => _p.setString(_kScreen, s);

  // --- Tweaks ---
  String? readAccent() => _p.getString(_kAccent);
  Future<void> writeAccent(String s) => _p.setString(_kAccent, s);

  bool? readDark() => _p.getBool(_kDark);
  Future<void> writeDark(bool b) => _p.setBool(_kDark, b);

  // --- Sync stamp (placeholder for future remote sync) ---
  String? readLastSync() => _p.getString(_kLastSync);
  Future<void> writeLastSync(String iso) => _p.setString(_kLastSync, iso);
}
