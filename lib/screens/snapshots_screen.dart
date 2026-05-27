import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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

String _catLabel(String cat) {
  switch (cat) {
    case 'hair': return 'hairstyle';
    case 'skin': return 'skincare';
    default: return cat;
  }
}

void openSnapshotAddSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const _AddSnapshotSheet(cat: 'body'),
  );
}

class SnapshotsScreen extends StatefulWidget {
  const SnapshotsScreen({super.key});

  @override
  State<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends State<SnapshotsScreen> {
  static const _cats = ['hair', 'body', 'skin'];
  int _catIndex = 0;
  String get cat => _cats[_catIndex];
  late final PageController _catCtrl;
  int? openIndex;

  @override
  void initState() {
    super.initState();
    _catCtrl = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().pruneDeletedSnapshotImages();
    });
  }

  @override
  void dispose() {
    _catCtrl.dispose();
    super.dispose();
  }

  void _goToCat(int index) {
    if (index == _catIndex) return;
    setState(() {
      _catIndex = index;
      openIndex = null;
    });
    _catCtrl.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final snaps = state.snapshots;
    final items = snaps[cat] ?? const [];

    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              theme: theme,
              value: cat,
              onChanged: (v) => _goToCat(_cats.indexOf(v)),
              items: [
                MapEntry('hair', 'Hairstyle  ${snaps['hair']?.length ?? 0}'),
                MapEntry('body', 'Body  ${snaps['body']?.length ?? 0}'),
                MapEntry('skin', 'Skincare  ${snaps['skin']?.length ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Add button
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
          const SizedBox(height: 6),

          // Swipeable category pages
          Expanded(
            child: PageView.builder(
              controller: _catCtrl,
              itemCount: _cats.length,
              onPageChanged: (i) => setState(() {
                _catIndex = i;
                openIndex = null;
              }),
              itemBuilder: (_, pageIndex) {
                final c = _cats[pageIndex];
                final catItems = snaps[c] ?? const [];
                return _CategoryPage(
                  cat: c,
                  items: catItems,
                  theme: theme,
                  onOpen: (i) => setState(() => openIndex = i),
                  onDelete: (s) async {
                    final ok = await confirmDelete(
                      context,
                      title: 'Delete snapshot?',
                      message: s.note.isEmpty ? s.date : '${s.note} · ${s.date}',
                    );
                    if (!ok || !context.mounted) return;
                    context.read<AppState>().deleteSnapshot(c, s.id);
                  },
                  onAddTap: () => _openAddSheet(context),
                );
              },
            ),
          ),
        ],
      ),

      if (openIndex != null && items.isNotEmpty)
        _SnapCarousel(
          snaps: items,
          initialIndex: openIndex!.clamp(0, items.length - 1),
          cat: cat,
          onClose: () => setState(() => openIndex = null),
          onDelete: (snap) async {
            final ok = await confirmDelete(
              context,
              title: 'Delete snapshot?',
              message: snap.note.isEmpty ? snap.date : '${snap.note} · ${snap.date}',
            );
            if (!ok || !context.mounted) return;
            context.read<AppState>().deleteSnapshot(cat, snap.id);
            if (items.length <= 1) setState(() => openIndex = null);
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

// ── Category page (single swipeable page inside PageView) ─────────────────────

class _CategoryPage extends StatelessWidget {
  final String cat;
  final List<Snapshot> items;
  final AppTheme theme;
  final void Function(int) onOpen;
  final void Function(Snapshot) onDelete;
  final VoidCallback onAddTap;

  const _CategoryPage({
    required this.cat,
    required this.items,
    required this.theme,
    required this.onOpen,
    required this.onDelete,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      child: items.isEmpty
          ? AppCard(
              theme: theme,
              pad: 32,
              child: Column(children: [
                Icon(LucideIcons.camera, size: 40, color: theme.muted),
                const SizedBox(height: 12),
                Text('No ${_catLabel(cat)} snapshots yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
                const SizedBox(height: 6),
                Text('Choose from gallery or take a photo',
                    style: TextStyle(fontSize: 13, color: theme.muted)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Add snapshot',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ]),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.7,
              ),
              itemBuilder: (_, i) {
                final s = items[i];
                return _SnapTile(
                  snap: s,
                  theme: theme,
                  onTap: () => onOpen(i),
                  onDelete: () => onDelete(s),
                );
              },
            ),
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
        const SizedBox(height: 6),
        if (snap.note.isNotEmpty)
          Text(snap.note, style: TextStyle(fontSize: 13, color: theme.ink, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(snap.date, style: TextStyle(fontSize: 11, color: theme.muted, fontWeight: FontWeight.w500)),
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
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.4), radius: 0.8,
              colors: [Colors.white.withOpacity(0.2), Colors.transparent],
              stops: const [0, 0.6],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Full-screen carousel overlay ──────────────────────────────────────────────

class _SnapCarousel extends StatefulWidget {
  final List<Snapshot> snaps;
  final int initialIndex;
  final String cat;
  final VoidCallback onClose;
  final void Function(Snapshot) onDelete;
  const _SnapCarousel({
    required this.snaps, required this.initialIndex, required this.cat,
    required this.onClose, required this.onDelete,
  });

  @override
  State<_SnapCarousel> createState() => _SnapCarouselState();
}

class _SnapCarouselState extends State<_SnapCarousel> {
  late final PageController _ctrl;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _download(BuildContext context, Snapshot snap) async {
    final path = snap.imagePath;
    if (path == null || !File(path).existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(behavior: SnackBarBehavior.floating, content: Text('No image to save')),
        );
      }
      return;
    }
    await Share.shareXFiles(
      [XFile(path)],
      text: snap.note.isNotEmpty ? snap.note : null,
    );
  }

  @override
  void didUpdateWidget(_SnapCarousel old) {
    super.didUpdateWidget(old);
    // If the snap at current page was deleted, snap to the nearest valid page
    if (widget.snaps.length != old.snaps.length) {
      final clamped = _page.clamp(0, widget.snaps.length - 1);
      if (clamped != _page) {
        setState(() => _page = clamped);
        _ctrl.jumpToPage(clamped);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snaps = widget.snaps;
    if (snaps.isEmpty) return const SizedBox.shrink();
    final snap = snaps[_page.clamp(0, snaps.length - 1)];

    return Material(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Stack(children: [
          // Swipeable pages
          PageView.builder(
            controller: _ctrl,
            itemCount: snaps.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SnapPage(snap: snaps[i]),
          ),

          // Top bar: close + counter
          Positioned(
            top: 12, left: 16, right: 16,
            child: Row(children: [
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_page + 1} / ${snaps.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),

          // Bottom bar: date + note + delete
          Positioned(
            bottom: 24, left: 20, right: 20,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (snap.note.isNotEmpty)
                  Text(snap.note,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(snap.date.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65), letterSpacing: 1.5, fontWeight: FontWeight.w500)),
              ])),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _download(context, snap),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                  child: const Icon(LucideIcons.download, color: Colors.white, size: 17),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => widget.onDelete(snap),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.75)),
                  child: const Icon(LucideIcons.trash2, color: Colors.white, size: 17),
                ),
              ),
            ]),
          ),

          // Dot indicators (shown only when > 1 snap)
          if (snaps.length > 1)
            Positioned(
              bottom: 80, left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < snaps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ]),
            ),
        ]),
      ),
    );
  }
}

class _SnapPage extends StatefulWidget {
  final Snapshot snap;
  const _SnapPage({required this.snap});

  @override
  State<_SnapPage> createState() => _SnapPageState();
}

class _SnapPageState extends State<_SnapPage> {
  final _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() => _transformCtrl.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final path = widget.snap.imagePath;
    final hasImage = path != null && File(path).existsSync();

    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _transformCtrl,
        minScale: 1.0,
        maxScale: 5.0,
        clipBehavior: Clip.none,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 140),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: hasImage
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [
                              HSLColor.fromAHSL(1, widget.snap.hue.toDouble(), 0.4, 0.6).toColor(),
                              HSLColor.fromAHSL(1, widget.snap.hue.toDouble(), 0.5, 0.3).toColor(),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
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
          Text('Add ${_catLabel(widget.cat)} snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
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
