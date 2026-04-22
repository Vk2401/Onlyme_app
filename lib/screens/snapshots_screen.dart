import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/snapshot.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/segmented.dart';
import '../widgets/primitives.dart';
import '../widgets/confirm_sheet.dart';

class SnapshotsScreen extends StatefulWidget {
  const SnapshotsScreen({super.key});

  @override
  State<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends State<SnapshotsScreen> {
  String cat = 'hair';
  Snapshot? open;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final snaps = state.snapshots;
    final items = snaps[cat] ?? const [];

    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          AppHeader(
            theme: theme,
            greeting: const Greeting(sub: 'Visual journal', title: 'Snapshots'),
            right: [
              HeaderBtn(theme: theme, icon: LucideIcons.camera, onTap: () => _openAddSheet(context, theme)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Segmented<String>(
              theme: theme, value: cat,
              onChanged: (v) => setState(() => cat = v),
              items: [
                MapEntry('hair', 'Hair  ${snaps['hair']?.length ?? 0}'),
                MapEntry('body', 'Body  ${snaps['body']?.length ?? 0}'),
                MapEntry('skin', 'Skin  ${snaps['skin']?.length ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(
                theme: theme, pad: 32,
                child: Column(children: [
                  Icon(LucideIcons.camera, size: 40, color: theme.muted),
                  const SizedBox(height: 12),
                  Text('No $cat snapshots yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
                  const SizedBox(height: 6),
                  Text('Tap the camera button to add one', style: TextStyle(fontSize: 13, color: theme.muted)),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => _openAddSheet(context, theme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Add snapshot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.7,
                ),
                itemBuilder: (_, i) {
                  final s = items[i];
                  return _SnapTile(
                    snap: s, theme: theme,
                    onTap: () => setState(() => open = s),
                    onDelete: () async {
                      final ok = await confirmDelete(
                        context,
                        title: 'Delete snapshot?',
                        message: s.note.isEmpty ? s.date : '${s.note} · ${s.date}',
                      );
                      if (!ok || !context.mounted) return;
                      context.read<AppState>().deleteSnapshot(cat, s.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),

      if (open != null)
        _SnapOverlay(
          snap: open!,
          cat: cat,
          onClose: () => setState(() => open = null),
          onDelete: () async {
            final snap = open!;
            final ok = await confirmDelete(
              context,
              title: 'Delete snapshot?',
              message: snap.note.isEmpty ? snap.date : '${snap.note} · ${snap.date}',
            );
            if (!ok || !context.mounted) return;
            context.read<AppState>().deleteSnapshot(cat, snap.id);
            setState(() => open = null);
          },
        ),
    ]);
  }

  void _openAddSheet(BuildContext context, AppTheme theme) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _AddSnapshotSheet(cat: cat),
    );
  }
}

// ── Snap tile ─────────────────────────────────────────────────────────────────

class _SnapTile extends StatelessWidget {
  final Snapshot snap;
  final AppTheme theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _SnapTile({required this.snap, required this.theme, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      behavior: HitTestBehavior.opaque,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _photoBox(snap.hue, snap.date)),
        const SizedBox(height: 8),
        Text(snap.note, style: TextStyle(fontSize: 13, color: theme.ink, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    final theme = context.read<AppState>().theme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Container(
        decoration: BoxDecoration(color: theme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), border: Border.all(color: theme.rule)),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(snap.note, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
          const SizedBox(height: 4),
          Text(snap.date, style: TextStyle(fontSize: 12, color: theme.muted)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () { Navigator.pop(context); onDelete(); },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: theme.danger, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Text('Delete snapshot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _photoBox(int hue, String date) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.55).toColor(),
              HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.30).toColor(),
            ],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4), radius: 0.8,
                colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                stops: const [0, 0.6],
              ),
            ),
          )),
          Positioned(top: 10, left: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(6)),
            child: Text(date, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          )),
        ]),
      ),
    );
  }
}

// ── Full-screen overlay ───────────────────────────────────────────────────────

class _SnapOverlay extends StatelessWidget {
  final Snapshot snap;
  final String cat;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  const _SnapOverlay({required this.snap, required this.cat, required this.onClose, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: GestureDetector(
        onTap: onClose,
        child: Container(color: Colors.black.withOpacity(0.85)),
      )),
      Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    HSLColor.fromAHSL(1, snap.hue.toDouble(), 0.4, 0.6).toColor(),
                    HSLColor.fromAHSL(1, snap.hue.toDouble(), 0.5, 0.3).toColor(),
                  ],
                )),
                child: Stack(children: [
                  Positioned(top: 14, right: 14, child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.4)),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                    ),
                  )),
                  Positioned(bottom: 14, right: 14, child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.7)),
                      child: const Icon(LucideIcons.trash2, color: Colors.white, size: 16),
                    ),
                  )),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(snap.date.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(snap.note, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      )),
    ]);
  }
}

// ── Add snapshot sheet ────────────────────────────────────────────────────────

class _AddSnapshotSheet extends StatefulWidget {
  final String cat;
  const _AddSnapshotSheet({required this.cat});

  @override
  State<_AddSnapshotSheet> createState() => _AddSnapshotSheetState();
}

class _AddSnapshotSheetState extends State<_AddSnapshotSheet> {
  final _note = TextEditingController();
  double _hue = 120;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.rule),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text('Add ${widget.cat} snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 18),

          // Color preview
          Center(child: Container(
            width: double.infinity, height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromAHSL(1, _hue, 0.45, 0.55).toColor(),
                  HSLColor.fromAHSL(1, _hue, 0.55, 0.30).toColor(),
                ],
              ),
            ),
          )),
          const SizedBox(height: 12),

          // Hue slider
          Text('Color tone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted, letterSpacing: 0.5)),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: _hue,
              min: 0, max: 359,
              activeColor: HSLColor.fromAHSL(1, _hue, 0.6, 0.5).toColor(),
              inactiveColor: theme.surface2,
              onChanged: (v) => setState(() => _hue = v),
            ),
          ),
          const SizedBox(height: 8),

          // Note field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _note,
              autofocus: true,
              style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Note (e.g. Fresh cut, 78.2 kg)',
                hintStyle: TextStyle(color: theme.muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 22),

          GestureDetector(
            onTap: () {
              if (_note.text.trim().isEmpty) return;
              context.read<AppState>().addSnapshot(
                widget.cat,
                note: _note.text.trim(),
                hue: _hue.round(),
              );
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: const Text('Add snapshot', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
