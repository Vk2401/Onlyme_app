import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../models/gym.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/confirm_sheet.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  late int selId;
  final _planNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selId = DateTime.now().weekday; // 1=Mon … 7=Sun, matches GymDay ids
  }

  @override
  void dispose() {
    _planNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final plan = state.gym;
    final todayId = DateTime.now().weekday;

    final day = plan.days.firstWhere((x) => x.id == selId, orElse: () => plan.days.first);
    final pct = day.exercises.isEmpty
        ? 0.0
        : day.exercises.where((e) => e.done).length / day.exercises.length;
    final weekDone = plan.days.where((x) => x.done).length;
    final activeDays = plan.days.where((x) => x.label.toLowerCase() != 'rest').length;

    final weights = state.weightLogs;
    final latestKg = weights.isEmpty ? null : weights.last.kg;
    final chartData = weights.length > 1 ? weights.map((w) => w.kg).toList() : <double>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: Greeting(sub: plan.name, title: 'Workout'),
          right: [
            HeaderBtn(
              theme: theme,
              icon: LucideIcons.pencil,
              onTap: () {
                _planNameCtrl.text = plan.name;
                _openEditPlanNameSheet(context, theme);
              },
            ),
          ],
        ),

        // Weekly overview card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 14, child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('This week', style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('$weekDone of $activeDays sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
              ])),
              Ring(pct: activeDays == 0 ? 0 : weekDone / activeDays, size: 42, stroke: 4,
                  color: theme.accent, track: theme.surface2,
                  child: Text('$weekDone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.ink))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              for (final d in plan.days)
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _DayPill(
                    day: d, selected: d.id == selId,
                    isToday: d.id == todayId,
                    theme: theme,
                    onTap: () => setState(() => selId = d.id),
                  ),
                )),
            ]),
          ])),
        ),

        const SizedBox(height: 18),

        // Day header + completion + rest toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _openEditDayLabelSheet(context, theme, day),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(day.id == todayId ? 'Today' : 'Session',
                      style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(day.label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.5)),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.pencil, size: 13, color: theme.accent),
                  ]),
                ]),
              ),
              Row(children: [
                // Rest day toggle chip
                GestureDetector(
                  onTap: () => state.toggleDayRest(day.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: day.isRest ? theme.muted.withOpacity(0.12) : theme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: day.isRest ? theme.rule : theme.accent.withOpacity(0.35)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(day.isRest ? LucideIcons.moon : LucideIcons.dumbbell,
                          size: 13, color: day.isRest ? theme.muted : theme.accent),
                      const SizedBox(width: 4),
                      Text(day.isRest ? 'Rest' : 'Train',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: day.isRest ? theme.muted : theme.accent)),
                    ]),
                  ),
                ),
                if (!day.isRest && day.exercises.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${(pct * 100).round()}%',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.accent, letterSpacing: -0.5)),
                    Text('DONE', style: TextStyle(fontSize: 10, color: theme.muted, fontWeight: FontWeight.w500)),
                  ]),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Exercises or rest day view
        if (day.isRest)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(theme: theme, pad: 30, child: Column(children: [
              const Text('🌿', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text('Rest day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
              const SizedBox(height: 4),
              Text('Recovery matters. Stretch & sleep well.', style: TextStyle(fontSize: 13, color: theme.muted)),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => state.toggleDayRest(day.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.accent.withOpacity(0.3)),
                  ),
                  child: Text('Switch to training day',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.accent)),
                ),
              ),
            ])),
          )
        else ...[
          for (var i = 0; i < day.exercises.length; i++)
            _DismissibleExercise(
              ex: day.exercises[i],
              index: i,
              theme: theme,
              onToggle: () => state.toggleExercise(day.id, i),
              onEdit: () => _openExerciseSheet(context, theme, dayId: day.id, exIndex: i, ex: day.exercises[i]),
              onDelete: () => state.deleteExercise(day.id, i),
            ),

          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(theme: theme, pad: 24, child: Column(children: [
                Icon(LucideIcons.dumbbell, size: 32, color: theme.muted),
                const SizedBox(height: 10),
                Text('No exercises yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.ink)),
                const SizedBox(height: 4),
                Text('Tap "Add exercise" below to get started', style: TextStyle(fontSize: 12, color: theme.muted)),
              ])),
            ),

          // Mark day done + add exercise
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => state.markDayDone(day.id, !day.done),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: day.done ? theme.success.withOpacity(0.15) : theme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: day.done ? theme.success : theme.rule),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(day.done ? LucideIcons.checkCircle : LucideIcons.circle,
                        size: 16, color: day.done ? theme.success : theme.muted),
                    const SizedBox(width: 6),
                    Text(day.done ? 'Session done' : 'Mark done',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: day.done ? theme.success : theme.ink)),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => _openExerciseSheet(context, theme, dayId: day.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.accent.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.plus, size: 16, color: theme.accent),
                    const SizedBox(width: 6),
                    Text('Add exercise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.accent)),
                  ]),
                ),
              )),
            ]),
          ),
        ],

        const SizedBox(height: 28),

        // Body weight section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            theme: theme,
            title: 'Body weight',
            action: 'Log',
            onAction: () => _openWeightLogSheet(context, theme),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 16, child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                latestKg == null
                    ? Text('—', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.muted))
                    : Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text(latestKg.toStringAsFixed(1), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.6)),
                        const SizedBox(width: 4),
                        Text('kg', style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
                      ]),
                if (weights.length >= 2) ...[
                  Row(children: [
                    Icon(
                      weights.last.kg <= weights.first.kg ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                      color: weights.last.kg <= weights.first.kg ? theme.success : theme.danger,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(weights.last.kg - weights.first.kg).abs().toStringAsFixed(1)} kg · ${weights.length} entries',
                      style: TextStyle(
                        color: weights.last.kg <= weights.first.kg ? theme.success : theme.danger,
                        fontSize: 12, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ],
              ],
            ),
            if (chartData.length >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(height: 80, child: _WeightChart(data: chartData, theme: theme)),
            ] else if (weights.isEmpty) ...[
              const SizedBox(height: 12),
              Text('Tap "Log" to record your weight', style: TextStyle(fontSize: 12, color: theme.muted)),
            ],
          ])),
        ),

        // Weight log list (last 5)
        if (weights.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              for (final w in weights.reversed.take(5))
                _WeightRow(entry: w, theme: theme, onDelete: () => state.deleteWeightLog(w.timestamp)),
            ]),
          ),
        ],
      ],
    );
  }

  void _openEditPlanNameSheet(BuildContext context, AppTheme theme) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: theme.rule)),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text('Edit plan name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
            const SizedBox(height: 16),
            _GField(theme: theme, hint: 'Plan name', controller: _planNameCtrl, autofocus: true),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                final name = _planNameCtrl.text.trim();
                if (name.isNotEmpty) context.read<AppState>().editGymPlanName(name);
                Navigator.of(ctx).pop();
              },
              child: _SubmitBtn(theme: theme, label: 'Save'),
            ),
          ]),
        ),
      ),
    );
  }

  void _openEditDayLabelSheet(BuildContext context, AppTheme theme, day) {
    final ctrl = TextEditingController(text: day.label);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: theme.rule)),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text('Edit day label', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
            const SizedBox(height: 4),
            Text('e.g. Push, Pull, Legs, Rest, Cardio', style: TextStyle(fontSize: 13, color: theme.muted)),
            const SizedBox(height: 16),
            _GField(theme: theme, hint: 'Label', controller: ctrl, autofocus: true),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                final lbl = ctrl.text.trim();
                if (lbl.isNotEmpty) context.read<AppState>().editGymDayLabel(day.id, lbl);
                Navigator.of(ctx).pop();
              },
              child: _SubmitBtn(theme: theme, label: 'Save'),
            ),
          ]),
        ),
      ),
    );
  }

  void _openExerciseSheet(BuildContext context, AppTheme theme, {required int dayId, int? exIndex, Exercise? ex}) {
    final nameCtrl = TextEditingController(text: ex?.name ?? '');
    final setsCtrl = TextEditingController(text: ex?.sets.toString() ?? '');
    final repsCtrl = TextEditingController(text: ex?.reps ?? '');
    final weightCtrl = TextEditingController(text: ex?.weight ?? '');
    final tutorialCtrl = TextEditingController(text: ex?.tutorialLink ?? '');
    String? pickedImagePath = ex?.imagePath;
    final editing = ex != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.rule),
            ),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Text(editing ? 'Edit exercise' : 'Add exercise',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
                const SizedBox(height: 16),
                _GField(theme: theme, hint: 'Exercise name', controller: nameCtrl, autofocus: !editing),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _GField(theme: theme, hint: 'Sets', controller: setsCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _GField(theme: theme, hint: 'Reps (e.g. 8 or 12/leg)', controller: repsCtrl)),
                ]),
                const SizedBox(height: 10),
                _GField(theme: theme, hint: 'Weight (e.g. 85 kg / bodyweight)', controller: weightCtrl),
                const SizedBox(height: 14),

                // Reference image picker
                Text('Reference image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                if (pickedImagePath != null && File(pickedImagePath!).existsSync())
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(pickedImagePath!), height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(top: 8, right: 8, child: GestureDetector(
                      onTap: () => setSheetState(() => pickedImagePath = null),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                      ),
                    )),
                  ])
                else
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () async {
                        final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (img == null) return;
                        final dir = await getApplicationDocumentsDirectory();
                        final exDir = Directory('${dir.path}/exercises');
                        if (!await exDir.exists()) await exDir.create(recursive: true);
                        final dest = File('${exDir.path}/ex_${DateTime.now().millisecondsSinceEpoch}.jpg');
                        await File(img.path).copy(dest.path);
                        setSheetState(() => pickedImagePath = dest.path);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.rule)),
                        child: Column(children: [
                          Icon(LucideIcons.image, color: theme.accent, size: 20),
                          const SizedBox(height: 6),
                          Text('Gallery', style: TextStyle(fontSize: 12, color: theme.ink, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(
                      onTap: () async {
                        final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (img == null) return;
                        final dir = await getApplicationDocumentsDirectory();
                        final exDir = Directory('${dir.path}/exercises');
                        if (!await exDir.exists()) await exDir.create(recursive: true);
                        final dest = File('${exDir.path}/ex_${DateTime.now().millisecondsSinceEpoch}.jpg');
                        await File(img.path).copy(dest.path);
                        setSheetState(() => pickedImagePath = dest.path);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.rule)),
                        child: Column(children: [
                          Icon(LucideIcons.camera, color: theme.accent, size: 20),
                          const SizedBox(height: 6),
                          Text('Camera', style: TextStyle(fontSize: 12, color: theme.ink, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    )),
                  ]),

                const SizedBox(height: 10),
                _GField(theme: theme, hint: 'Tutorial link (YouTube / video URL)', controller: tutorialCtrl),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final sets = int.tryParse(setsCtrl.text.trim()) ?? 3;
                    final link = tutorialCtrl.text.trim().isEmpty ? null : tutorialCtrl.text.trim();
                    final state = ctx.read<AppState>();
                    if (editing && exIndex != null) {
                      state.editExercise(dayId, exIndex, Exercise(
                        name: nameCtrl.text.trim(),
                        sets: sets,
                        reps: repsCtrl.text.trim().isEmpty ? '—' : repsCtrl.text.trim(),
                        weight: weightCtrl.text.trim().isEmpty ? '—' : weightCtrl.text.trim(),
                        done: ex.done,
                        imagePath: pickedImagePath,
                        tutorialLink: link,
                      ));
                    } else {
                      state.addExercise(dayId,
                        name: nameCtrl.text.trim(),
                        sets: sets,
                        reps: repsCtrl.text.trim().isEmpty ? '—' : repsCtrl.text.trim(),
                        weight: weightCtrl.text.trim().isEmpty ? '—' : weightCtrl.text.trim(),
                        imagePath: pickedImagePath,
                        tutorialLink: link,
                      );
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: _SubmitBtn(theme: theme, label: editing ? 'Save changes' : 'Add exercise'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _openWeightLogSheet(BuildContext context, AppTheme theme) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: theme.rule)),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text('Log body weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.ink),
                  decoration: InputDecoration(border: InputBorder.none, isDense: true, hintText: '0.0', hintStyle: TextStyle(color: theme.muted)),
                )),
                Text('kg', style: TextStyle(fontSize: 18, color: theme.muted, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                final kg = double.tryParse(ctrl.text.trim());
                if (kg != null && kg > 0) {
                  ctx.read<AppState>().logWeight(kg);
                  Navigator.of(ctx).pop();
                }
              },
              child: _SubmitBtn(theme: theme, label: 'Log weight'),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Dismissible exercise row ──────────────────────────────────────────────────

class _DismissibleExercise extends StatelessWidget {
  final Exercise ex;
  final int index;
  final AppTheme theme;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DismissibleExercise({required this.ex, required this.index, required this.theme, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(ex.name + ex.sets.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.fromLTRB(0, 0, 28, 0),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(color: theme.danger, borderRadius: BorderRadius.circular(18)),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'Delete exercise?',
        message: '${ex.name} · ${ex.sets}×${ex.reps}',
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: _ExerciseRow(ex: ex, index: index, onToggle: onToggle, onEdit: onEdit, onDelete: onDelete, theme: theme),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme theme;
  final bool accent;
  const _StatChip({required this.label, required this.value, required this.theme, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final bg = accent ? theme.accent.withOpacity(0.12) : theme.surface2;
    final fg = accent ? theme.accent : theme.muted;
    final valueFg = accent ? theme.accent : theme.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg, letterSpacing: 0.2)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueFg)),
      ]),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise ex;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final AppTheme theme;
  const _ExerciseRow({required this.ex, required this.index, required this.onToggle, required this.onEdit, required this.onDelete, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasImage = ex.imagePath != null && File(ex.imagePath!).existsSync();
    final hasLink = ex.tutorialLink != null && ex.tutorialLink!.isNotEmpty;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: ex.done ? 0.5 : 1,
      child: AppCard(
        theme: theme,
        pad: 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Main row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Numbered circle / checkmark
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ex.done ? theme.accent : theme.accent.withOpacity(0.12),
                    border: ex.done ? null : Border.all(color: theme.accent.withOpacity(0.35), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: ex.done
                      ? const Icon(LucideIcons.check, size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.accent,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + stat chips
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    ex.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.ink,
                      letterSpacing: -0.2,
                      decoration: ex.done ? TextDecoration.lineThrough : null,
                      decorationColor: theme.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _StatChip(label: 'SETS', value: '${ex.sets}', theme: theme),
                    _StatChip(label: 'REPS', value: ex.reps, theme: theme),
                    _StatChip(label: 'WT', value: ex.weight, theme: theme, accent: true),
                  ]),
                ]),
              ),
              // Popup menu
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    final ok = await confirmDelete(context,
                        title: 'Delete exercise?', message: '${ex.name} · ${ex.sets}×${ex.reps}');
                    if (ok) onDelete();
                  }
                },
                icon: Icon(LucideIcons.moreVertical, size: 18, color: theme.muted),
                padding: EdgeInsets.zero,
                color: theme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(LucideIcons.pencil, size: 16, color: theme.ink),
                      const SizedBox(width: 10),
                      Text('Edit', style: TextStyle(color: theme.ink, fontSize: 14)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(LucideIcons.trash2, size: 16, color: theme.danger),
                      const SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: theme.danger, fontSize: 14)),
                    ]),
                  ),
                ],
              ),
            ]),
          ),

          // Tutorial image
          if (hasImage) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(ex.imagePath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 48,
                    decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LucideIcons.imageOff, size: 16, color: theme.muted),
                      const SizedBox(width: 6),
                      Text('Image unavailable', style: TextStyle(fontSize: 12, color: theme.muted)),
                    ]),
                  ),
                ),
              ),
            ),
          ],

          // Tutorial link
          if (hasLink) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(ex.tutorialLink!), mode: LaunchMode.externalApplication),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.accent.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.playCircle, size: 16, color: theme.accent),
                    const SizedBox(width: 8),
                    Text('Watch tutorial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.accent)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Weight chart ──────────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<double> data;
  final AppTheme theme;
  const _WeightChart({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      return CustomPaint(
        size: Size(box.maxWidth, box.maxHeight),
        painter: _ChartPainter(data: data, color: theme.accent),
      );
    });
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _ChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    const pad = 6.0;
    final minV = data.reduce((a, b) => a < b ? a : b) - 0.3;
    final maxV = data.reduce((a, b) => a > b ? a : b) + 0.3;
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    final pts = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = pad + (i / (data.length - 1)) * (size.width - pad * 2);
      final y = pad + (1 - (data[i] - minV) / range) * (size.height - pad * 2);
      pts.add(Offset(x, y));
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }

    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(pts.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.data != data || old.color != color;
}

// ── Weight log row ────────────────────────────────────────────────────────────

class _WeightRow extends StatelessWidget {
  final dynamic entry;
  final AppTheme theme;
  final VoidCallback onDelete;
  const _WeightRow({required this.entry, required this.theme, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.timestamp),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: theme.danger, borderRadius: BorderRadius.circular(12)),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 16),
      ),
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'Delete weight entry?',
        message: '${entry.kg.toStringAsFixed(1)} kg · ${entry.dateStr}',
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.rule)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(entry.dateStr, style: TextStyle(fontSize: 13, color: theme.muted)),
          Text('${entry.kg.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.ink)),
        ]),
      ),
    );
  }
}

// ── Day pill ──────────────────────────────────────────────────────────────────

class _DayPill extends StatelessWidget {
  final GymDay day;
  final bool selected;
  final bool isToday;
  final AppTheme theme;
  final VoidCallback onTap;
  const _DayPill({required this.day, required this.selected, required this.isToday, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rest = day.label.toLowerCase() == 'rest';
    final bg = selected ? theme.accent : (day.done ? theme.accent.withOpacity(0.13) : theme.surface2);
    final fg = selected ? Colors.white : (day.done ? theme.accent : theme.ink);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: isToday && !selected ? Border.all(color: theme.accent, width: 1.5) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Opacity(opacity: 0.75, child: Text(day.short, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg))),
          const SizedBox(height: 4),
          Text(
            rest ? '—' : (day.done ? '✓' : (isToday ? '•' : '')),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg),
          ),
        ]),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _GField extends StatelessWidget {
  final AppTheme theme;
  final String hint;
  final TextEditingController controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  const _GField({required this.theme, required this.hint, required this.controller, this.autofocus = false, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: theme.muted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SubmitBtn extends StatelessWidget {
  final AppTheme theme;
  final String label;
  const _SubmitBtn({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
