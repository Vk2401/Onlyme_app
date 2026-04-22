import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../data/seed_data.dart';
import '../models/snapshot.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/segmented.dart';

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
    final theme = context.watch<AppState>().theme;
    final items = seedSnaps[cat] ?? const [];
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          AppHeader(
            theme: theme, greeting: const Greeting(sub: 'Visual journal', title: 'Snapshots'),
            right: [HeaderBtn(theme: theme, icon: LucideIcons.camera)],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Segmented<String>(
              theme: theme, value: cat,
              onChanged: (v) => setState(() => cat = v),
              items: [
                MapEntry('hair', 'Hair  ${seedSnaps['hair']?.length ?? 0}'),
                MapEntry('body', 'Body  ${seedSnaps['body']?.length ?? 0}'),
                MapEntry('skin', 'Skin  ${seedSnaps['skin']?.length ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (_, i) {
                final s = items[i];
                final big = i == 0;
                return _SnapTile(snap: s, big: big, theme: theme, onTap: () => setState(() => open = s));
              },
            ),
          ),
        ],
      ),
      if (open != null) _SnapOverlay(
        snap: open!,
        onClose: () => setState(() => open = null),
      ),
    ]);
  }
}

class _SnapTile extends StatelessWidget {
  final Snapshot snap;
  final bool big;
  final AppTheme theme;
  final VoidCallback onTap;
  const _SnapTile({required this.snap, required this.big, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _photoBox(snap.hue, snap.date)),
          const SizedBox(height: 8),
          Text(snap.note, style: TextStyle(fontSize: 13, color: theme.ink, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
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
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(date, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          )),
        ]),
      ),
    );
  }
}

class _SnapOverlay extends StatelessWidget {
  final Snapshot snap;
  final VoidCallback onClose;
  const _SnapOverlay({required this.snap, required this.onClose});

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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
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
