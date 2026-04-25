import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().pruneDeletedSnapshotImages();
    });
  }

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
              HeaderBtn(theme: theme, icon: LucideIcons.camera, onTap: () => _openAddSheet(context)),
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
          const SizedBox(height: 12),

          // Prominent add button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: GestureDetector(
              onTap: () => _openAddSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.accent.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(LucideIcons.camera, color: theme.accent, size: 18),
                  const SizedBox(width: 10),
                  Text('Add snapshot', style: TextStyle(color: theme.accent, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),

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
                  Text('Choose from gallery or take a photo', style: TextStyle(fontSize: 13, color: theme.muted)),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => _openAddSheet(context),
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

  void _openAddSheet(BuildContext context) {
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
      behavior: HitTestBehavior.opaque,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Stack(children: [
          Positioned.fill(child: _imageBox()),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.trash2, color: Colors.white, size: 13),
              ),
            ),
          ),
        ])),
        if (snap.note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(snap.note, style: TextStyle(fontSize: 13, color: theme.ink, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }

  Widget _imageBox() {
    final path = snap.imagePath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    }
    return _gradientBox();
  }

  Widget _gradientBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1, snap.hue.toDouble(), 0.45, 0.55).toColor(),
              HSLColor.fromAHSL(1, snap.hue.toDouble(), 0.55, 0.30).toColor(),
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
            child: Text(snap.date, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
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
              child: Stack(fit: StackFit.expand, children: [
                _imageWidget(),
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
          const SizedBox(height: 16),
          Text(snap.date.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), letterSpacing: 1.5)),
          if (snap.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(snap.note, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ]),
      )),
    ]);
  }

  Widget _imageWidget() {
    final path = snap.imagePath;
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, snap.hue.toDouble(), 0.4, 0.6).toColor(),
            HSLColor.fromAHSL(1, snap.hue.toDouble(), 0.5, 0.3).toColor(),
          ],
        ),
      ),
    );
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
  XFile? _picked;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source, imageQuality: 85);
      if (img != null && mounted) setState(() => _picked = img);
    } catch (_) {}
  }

  Future<void> _save(BuildContext context) async {
    if (_picked == null && _note.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    String? internalPath;
    if (_picked != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final snapDir = Directory('${dir.path}/snapshots');
        if (!await snapDir.exists()) await snapDir.create(recursive: true);
        final fileName = 'snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final dest = File('${snapDir.path}/$fileName');
        await File(_picked!.path).copy(dest.path);
        internalPath = dest.path;
      } catch (_) {}
    }
    if (!mounted) return;
    state.addSnapshot(widget.cat, note: _note.text.trim(), hue: 120, imagePath: internalPath);
    nav.pop();
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
          const SizedBox(height: 16),

          // Image preview or picker buttons
          if (_picked != null)
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(_picked!.path),
                  height: 200, width: double.infinity, fit: BoxFit.cover,
                ),
              ),
              Positioned(top: 8, right: 8, child: GestureDetector(
                onTap: () => setState(() => _picked = null),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                ),
              )),
            ])
          else
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.rule),
                  ),
                  child: Column(children: [
                    Icon(LucideIcons.image, color: theme.accent, size: 22),
                    const SizedBox(height: 6),
                    Text('Gallery', style: TextStyle(fontSize: 13, color: theme.ink, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.rule),
                  ),
                  child: Column(children: [
                    Icon(LucideIcons.camera, color: theme.accent, size: 22),
                    const SizedBox(height: 6),
                    Text('Camera', style: TextStyle(fontSize: 13, color: theme.ink, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
            ]),

          const SizedBox(height: 14),

          // Note field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _note,
              style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Caption (optional)',
                hintStyle: TextStyle(color: theme.muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 22),

          GestureDetector(
            onTap: _saving ? null : () => _save(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _saving ? theme.muted : theme.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [if (!_saving) BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: Text(
                _saving ? 'Saving…' : 'Add snapshot',
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
