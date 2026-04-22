import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/vault_entry.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/confirm_sheet.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final entries = state.vault;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Passwords · local only', title: 'Vault'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.plus, onTap: () => _openSheet(context))],
        ),

        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(theme: theme, pad: 32, child: Column(children: [
              Icon(LucideIcons.lock, size: 40, color: theme.muted),
              const SizedBox(height: 12),
              Text('No passwords saved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
              const SizedBox(height: 6),
              Text('Stored locally in this device', style: TextStyle(fontSize: 13, color: theme.muted)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _openSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Add entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ])),
          )
        else
          for (final v in entries)
            _VaultDismiss(
              entry: v,
              onTap: () => _openDetail(context, v),
              onDelete: () => context.read<AppState>().deleteVaultEntry(v.id),
            ),
      ],
    );
  }

  void _openSheet(BuildContext context, {VaultEntry? entry}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _VaultSheet(entry: entry),
    );
  }

  void _openDetail(BuildContext context, VaultEntry v) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _VaultDetail(entry: v, onEdit: () {
        Navigator.pop(context);
        _openSheet(context, entry: v);
      }),
    );
  }
}

class _VaultDismiss extends StatelessWidget {
  final VaultEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _VaultDismiss({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Dismissible(
      key: ValueKey(entry.id),
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
        title: 'Delete password entry?',
        message: entry.title,
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: AppCard(theme: theme, pad: 14, onTap: onTap, child: Row(children: [
          IconChip(
            bg: const Color(0xFFEF4444).withOpacity(0.13), size: 40,
            child: const Icon(LucideIcons.lock, color: Color(0xFFEF4444), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.1)),
              const SizedBox(height: 2),
              Text(
                (entry.username != null && entry.username!.isNotEmpty)
                    ? '${entry.username}  ·  ••••••••'
                    : '••••••••',
                style: TextStyle(fontSize: 12, color: theme.muted, letterSpacing: 1),
              ),
            ],
          )),
          Icon(LucideIcons.chevronRight, color: theme.muted, size: 16),
        ])),
      ),
    );
  }
}

// ── Detail bottom sheet ─────────────────────────────────────────────────────

class _VaultDetail extends StatefulWidget {
  final VaultEntry entry;
  final VoidCallback onEdit;
  const _VaultDetail({required this.entry, required this.onEdit});

  @override
  State<_VaultDetail> createState() => _VaultDetailState();
}

class _VaultDetailState extends State<_VaultDetail> {
  bool reveal = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    final e = widget.entry;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.rule),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: Text(e.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.4))),
          GestureDetector(
            onTap: widget.onEdit,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: theme.rule), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.pencil, size: 12, color: theme.ink),
                const SizedBox(width: 5),
                Text('Edit', style: TextStyle(fontSize: 12, color: theme.ink, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 18),

        if (e.username != null && e.username!.isNotEmpty)
          _detailRow(theme, 'Username', e.username!, icon: LucideIcons.user, onCopy: () => _copy(context, e.username!, 'Username')),
        if (e.username != null && e.username!.isNotEmpty) const SizedBox(height: 10),

        _detailRow(
          theme, 'Password',
          reveal ? e.password : '•' * e.password.length.clamp(4, 14),
          icon: LucideIcons.key,
          onCopy: () => _copy(context, e.password, 'Password'),
          trailing: GestureDetector(
            onTap: () => setState(() => reveal = !reveal),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(reveal ? LucideIcons.eyeOff : LucideIcons.eye, size: 16, color: theme.muted),
            ),
          ),
        ),

        if (e.url != null && e.url!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _detailRow(theme, 'URL', e.url!, icon: LucideIcons.link, onCopy: () => _copy(context, e.url!, 'URL')),
        ],

        if (e.note != null && e.note!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _detailRow(theme, 'Note', e.note!, icon: LucideIcons.fileText, multiline: true),
        ],

        const SizedBox(height: 22),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: theme.bg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.rule),
            ),
            alignment: Alignment.center,
            child: Text('Close', style: TextStyle(fontSize: 14, color: theme.ink, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _detailRow(theme, String label, String value,
      {required IconData icon, VoidCallback? onCopy, Widget? trailing, bool multiline = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, size: 16, color: theme.muted),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: theme.muted, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: multiline ? 6 : 1,
                overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.3)),
          ],
        )),
        if (trailing != null) trailing,
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(LucideIcons.copy, size: 16, color: theme.muted),
            ),
          ),
      ]),
    );
  }

  void _copy(BuildContext context, String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$what copied'),
      duration: const Duration(seconds: 1),
    ));
  }
}

// ── Add / edit sheet ────────────────────────────────────────────────────────

class _VaultSheet extends StatefulWidget {
  final VaultEntry? entry;
  const _VaultSheet({this.entry});

  @override
  State<_VaultSheet> createState() => _VaultSheetState();
}

class _VaultSheetState extends State<_VaultSheet> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _url;
  late final TextEditingController _note;
  bool _reveal = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _title = TextEditingController(text: e?.title ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController(text: e?.password ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _title.dispose(); _username.dispose(); _password.dispose();
    _url.dispose(); _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    final isEdit = widget.entry != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
            Text(isEdit ? 'Edit entry' : 'New entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
            const SizedBox(height: 16),

            _field(theme, _title, 'Title (required)', LucideIcons.tag, autofocus: !isEdit),
            const SizedBox(height: 10),
            _field(theme, _username, 'Username (optional)', LucideIcons.user),
            const SizedBox(height: 10),
            _passwordField(theme),
            const SizedBox(height: 10),
            _field(theme, _url, 'URL (optional)', LucideIcons.link, keyboard: TextInputType.url),
            const SizedBox(height: 10),
            _field(theme, _note, 'Note (optional)', LucideIcons.fileText, maxLines: 3),
            const SizedBox(height: 22),

            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
                ),
                alignment: Alignment.center,
                child: Text(isEdit ? 'Save changes' : 'Save entry',
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    final password = _password.text;
    if (title.isEmpty || password.isEmpty) return;
    final state = context.read<AppState>();
    final u = _username.text.trim();
    final url = _url.text.trim();
    final note = _note.text.trim();
    if (widget.entry != null) {
      state.editVaultEntry(widget.entry!.copyWith(
        title: title,
        username: u.isEmpty ? null : u,
        password: password,
        url: url.isEmpty ? null : url,
        note: note.isEmpty ? null : note,
        clearUsername: u.isEmpty,
        clearUrl: url.isEmpty,
        clearNote: note.isEmpty,
      ));
    } else {
      state.addVaultEntry(
        title: title,
        username: u.isEmpty ? null : u,
        password: password,
        url: url.isEmpty ? null : url,
        note: note.isEmpty ? null : note,
      );
    }
    Navigator.of(context).pop();
  }

  Widget _field(theme, TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard, bool autofocus = false, int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
          child: Icon(icon, size: 18, color: theme.muted),
        ),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: c,
          autofocus: autofocus,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: theme.muted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        )),
      ]),
    );
  }

  Widget _passwordField(theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(LucideIcons.key, size: 18, color: theme.muted),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _password,
          obscureText: !_reveal,
          style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Password (required)',
            hintStyle: TextStyle(color: theme.muted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        )),
        GestureDetector(
          onTap: () => setState(() => _reveal = !_reveal),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(_reveal ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: theme.muted),
          ),
        ),
      ]),
    );
  }
}
