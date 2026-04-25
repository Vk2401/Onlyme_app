import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/note.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/confirm_sheet.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final notes = state.notes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Quick thoughts', title: 'Notes'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.plus, onTap: () => _openSheet(context))],
        ),

        // Prominent add button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GestureDetector(
            onTap: () => _openSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.accent.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(LucideIcons.plus, color: theme.accent, size: 18),
                const SizedBox(width: 10),
                Text('New note', style: TextStyle(color: theme.accent, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),

        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(theme: theme, pad: 32, child: Column(children: [
              Icon(LucideIcons.fileText, size: 40, color: theme.muted),
              const SizedBox(height: 12),
              Text('No notes yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
              const SizedBox(height: 6),
              Text('Tap + to write a note', style: TextStyle(fontSize: 13, color: theme.muted)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _openSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Add note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ])),
          )
        else
          for (final n in notes)
            _NoteDismiss(
              note: n,
              onTap: () => _openSheet(context, note: n),
              onDelete: () => context.read<AppState>().deleteNote(n.id),
            ),
      ],
    );
  }

  void _openSheet(BuildContext context, {Note? note}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _NoteSheet(note: note),
    );
  }
}

class _NoteDismiss extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NoteDismiss({required this.note, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Dismissible(
      key: ValueKey(note.id),
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
        title: 'Delete note?',
        message: note.title.isEmpty ? note.body : note.title,
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: AppCard(theme: theme, pad: 16, onTap: onTap, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (note.title.isNotEmpty)
                  Text(note.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.2)),
                if (note.title.isNotEmpty && note.body.isNotEmpty) const SizedBox(height: 4),
                if (note.body.isNotEmpty)
                  Text(note.body,
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: theme.ink2, height: 1.4)),
              ])),
              GestureDetector(
                onTap: onDelete, behavior: HitTestBehavior.opaque,
                child: Padding(padding: const EdgeInsets.only(left: 8),
                    child: Icon(LucideIcons.trash2, size: 15, color: theme.danger)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(LucideIcons.clock, size: 11, color: theme.muted),
              const SizedBox(width: 4),
              Text(_formatDate(DateTime.fromMillisecondsSinceEpoch(note.createdAt)),
                  style: TextStyle(fontSize: 11, color: theme.muted, fontWeight: FontWeight.w500)),
            ]),
          ],
        )),
      ),
    );
  }
}

class _NoteSheet extends StatefulWidget {
  final Note? note;
  const _NoteSheet({this.note});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _body = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    final isEdit = widget.note != null;
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
          Text(isEdit ? 'Edit note' : 'New note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _title,
              autofocus: !isEdit,
              style: TextStyle(fontSize: 16, color: theme.ink, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
                hintStyle: TextStyle(color: theme.muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _body,
              maxLines: 6,
              minLines: 4,
              style: TextStyle(fontSize: 15, color: theme.ink, height: 1.4),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write something...',
                hintStyle: TextStyle(color: theme.muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 22),

          GestureDetector(
            onTap: () {
              final title = _title.text.trim();
              final body = _body.text.trim();
              if (title.isEmpty && body.isEmpty) return;
              final state = context.read<AppState>();
              if (isEdit) {
                state.editNote(widget.note!.copyWith(title: title, body: body));
              } else {
                state.addNote(title: title, body: body);
              }
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
              child: Text(isEdit ? 'Save changes' : 'Add note',
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
