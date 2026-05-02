import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app_state.dart';
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
import '../theme/app_theme.dart';

const _kPayloadVersion = 1;

class ImportResult {
  final bool ok;
  final String message;
  const ImportResult(this.ok, this.message);
}

/// Bundle every AppState domain into a single JSON payload and hand it to
/// the native share sheet. Returns the file path used (for debugging).
Future<String> exportAll(AppState state) async {
  final payload = <String, dynamic>{
    'app': 'onlyme',
    'version': _kPayloadVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'data': {
      'tasks': state.tasks.map((t) => t.toJson()).toList(),
      'debts': state.debts.map((d) => d.toJson()).toList(),
      'events': state.events.map((e) => e.toJson()).toList(),
      'gym': () {
        final gymJson = Map<String, dynamic>.from(state.gym.toJson());
        gymJson['days'] = (state.gym.days).map((day) {
          final dayJson = Map<String, dynamic>.from(day.toJson());
          dayJson['exercises'] = day.exercises.map((ex) {
            final exJson = Map<String, dynamic>.from(ex.toJson());
            if (ex.imagePath != null) {
              try {
                exJson['imageData'] = base64Encode(File(ex.imagePath!).readAsBytesSync());
              } catch (_) {}
              exJson.remove('imagePath');
            }
            return exJson;
          }).toList();
          return dayJson;
        }).toList();
        return gymJson;
      }(),
      'snapshots': state.snapshots.map((k, v) => MapEntry(k, v.map((s) {
        final j = Map<String, dynamic>.from(s.toJson());
        if (s.imagePath != null) {
          try {
            j['imageData'] = base64Encode(File(s.imagePath!).readAsBytesSync());
          } catch (_) {}
          j.remove('imagePath');
        }
        return j;
      }).toList())),
      'weightLogs': state.weightLogs.map((w) => w.toJson()).toList(),
      'profile': () {
        final j = Map<String, dynamic>.from(state.profile.toJson());
        if (state.profile.alarmSoundPath != null) {
          try {
            j['alarmSoundData'] = base64Encode(File(state.profile.alarmSoundPath!).readAsBytesSync());
            j['alarmSoundExt'] = state.profile.alarmSoundPath!.split('.').last;
          } catch (_) {}
          j.remove('alarmSoundPath');
        }
        return j;
      }(),
      'notes': state.notes.map((n) => n.toJson()).toList(),
      'links': state.links.map((l) => l.toJson()).toList(),
      'vault': state.vault.map((v) => v.toJson()).toList(),
      'expenses': state.expenses.map((e) => e.toJson()).toList(),
      'accent': state.theme.accentKey.name,
      'dark': state.theme.dark,
    },
  };

  final dir = await getTemporaryDirectory();
  final stamp = _stamp(DateTime.now());
  final file = File('${dir.path}/onlyme-backup-$stamp.json');
  await file.writeAsString(jsonEncode(payload), flush: true);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: 'onlyme-backup-$stamp.json')],
    subject: 'Only me — backup $stamp',
  );
  return file.path;
}

/// Read a JSON file produced by [exportAll] and replace every domain in
/// storage. Call [AppState.reloadFromStorage] after this returns ok=true.
Future<ImportResult> importAll(AppState state, File f) async {
  try {
    final raw = await f.readAsString();
    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic>) {
      return const ImportResult(false, 'File is not a valid JSON object');
    }
    if (map['app'] != 'onlyme') {
      return const ImportResult(false, 'Not an Only me backup file');
    }
    final version = map['version'];
    if (version is! int || version > _kPayloadVersion) {
      return ImportResult(false, 'Unsupported backup version: $version');
    }
    final data = map['data'];
    if (data is! Map<String, dynamic>) {
      return const ImportResult(false, 'Backup is missing the data section');
    }

    final s = state.storage;

    if (data['tasks'] is List) {
      await s.writeTasks(
        (data['tasks'] as List).map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['debts'] is List) {
      await s.writeDebts(
        (data['debts'] as List).map((e) => Debt.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['events'] is List) {
      await s.writeEvents(
        (data['events'] as List).map((e) => PlannedEvent.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['gym'] is Map) {
      final gymMap = Map<String, dynamic>.from((data['gym'] as Map).cast<String, dynamic>());
      if (gymMap['days'] is List) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final exDir = Directory('${appDocDir.path}/exercises');
        if (!await exDir.exists()) await exDir.create(recursive: true);
        gymMap['days'] = await Future.wait(
          (gymMap['days'] as List).map((dayRaw) async {
            final dayMap = Map<String, dynamic>.from(dayRaw as Map);
            if (dayMap['exercises'] is List) {
              dayMap['exercises'] = await Future.wait(
                (dayMap['exercises'] as List).map((exRaw) async {
                  final exMap = Map<String, dynamic>.from(exRaw as Map);
                  if (exMap['imageData'] is String) {
                    try {
                      final bytes = base64Decode(exMap['imageData'] as String);
                      final fileName = 'ex_${DateTime.now().microsecondsSinceEpoch}.jpg';
                      final imgFile = File('${exDir.path}/$fileName');
                      await imgFile.writeAsBytes(bytes);
                      exMap['imagePath'] = imgFile.path;
                    } catch (_) {}
                    exMap.remove('imageData');
                  }
                  return exMap;
                }),
              );
            }
            return dayMap;
          }),
        );
      }
      await s.writeGym(GymPlan.fromJson(gymMap));
    }
    if (data['snapshots'] is Map) {
      final rawMap = (data['snapshots'] as Map).cast<String, dynamic>();
      final appDocDir = await getApplicationDocumentsDirectory();
      final snapDir = Directory('${appDocDir.path}/snapshots');
      if (!await snapDir.exists()) await snapDir.create(recursive: true);
      final parsed = <String, List<Snapshot>>{};
      for (final entry in rawMap.entries) {
        final snaps = <Snapshot>[];
        for (final item in (entry.value as List)) {
          final j = Map<String, dynamic>.from(item as Map);
          String? imagePath;
          if (j['imageData'] is String) {
            try {
              final bytes = base64Decode(j['imageData'] as String);
              final fileName = 'snap_${j['id']}.jpg';
              final imgFile = File('${snapDir.path}/$fileName');
              await imgFile.writeAsBytes(bytes);
              imagePath = imgFile.path;
            } catch (_) {}
            j.remove('imageData');
          }
          j['imagePath'] = imagePath;
          snaps.add(Snapshot.fromJson(j));
        }
        parsed[entry.key] = snaps;
      }
      await s.writeSnapshots(parsed);
    }
    if (data['weightLogs'] is List) {
      await s.writeWeightLogs(
        (data['weightLogs'] as List).map((e) => WeightEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['profile'] is Map) {
      final pj = Map<String, dynamic>.from((data['profile'] as Map).cast<String, dynamic>());
      String? alarmPath;
      if (pj['alarmSoundData'] is String) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final alarmsDir = Directory('${appDocDir.path}/alarms');
          if (!await alarmsDir.exists()) await alarmsDir.create(recursive: true);
          final ext = (pj['alarmSoundExt'] as String?) ?? 'mp3';
          final dest = File('${alarmsDir.path}/alarm_sound.$ext');
          await dest.writeAsBytes(base64Decode(pj['alarmSoundData'] as String));
          alarmPath = dest.path;
        } catch (_) {}
        pj.remove('alarmSoundData');
        pj.remove('alarmSoundExt');
      }
      pj['alarmSoundPath'] = alarmPath;
      await s.writeProfile(Profile.fromJson(pj));
    }
    if (data['notes'] is List) {
      await s.writeNotes(
        (data['notes'] as List).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['links'] is List) {
      await s.writeLinks(
        (data['links'] as List).map((e) => SavedLink.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['vault'] is List) {
      await s.writeVault(
        (data['vault'] as List).map((e) => VaultEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['expenses'] is List) {
      await s.writeExpenses(
        (data['expenses'] as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data['accent'] is String) {
      final a = AccentKey.values.firstWhere(
        (e) => e.name == data['accent'],
        orElse: () => state.theme.accentKey,
      );
      await s.writeAccent(a.name);
    }
    if (data['dark'] is bool) {
      await s.writeDark(data['dark'] as bool);
    }

    await state.reloadFromStorage();
    // Re-plan every scheduledAt so imported tasks/events start firing.
    await state.replayScheduledNotifications();
    return const ImportResult(true, 'Backup restored');
  } catch (e) {
    return ImportResult(false, 'Import failed: $e');
  }
}

String _stamp(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}';
}
