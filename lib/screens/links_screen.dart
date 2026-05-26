import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../models/saved_link.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/confirm_sheet.dart';

void openLinkAddSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const _LinkSheet(),
  );
}

class LinksScreen extends StatelessWidget {
  const LinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final links = state.links;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Bookmarks', title: 'Saved links'),
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
                Text('Save a link', style: TextStyle(color: theme.accent, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),

        if (links.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(theme: theme, pad: 32, child: Column(children: [
              Icon(LucideIcons.link, size: 40, color: theme.muted),
              const SizedBox(height: 12),
              Text('No links saved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
              const SizedBox(height: 6),
              Text('Tap + to save a link', style: TextStyle(fontSize: 13, color: theme.muted)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _openSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Add link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ])),
          )
        else
          for (final l in links)
            _LinkDismiss(
              link: l,
              onTap: () => _openUrl(context, l.url),
              onEdit: () => _openSheet(context, link: l),
              onDelete: () => context.read<AppState>().deleteLink(l.id),
            ),
      ],
    );
  }

  void _openSheet(BuildContext context, {SavedLink? link}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _LinkSheet(link: link),
    );
  }

  Future<void> _openUrl(BuildContext context, String raw) async {
    final url = _normalizeUrl(raw);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open $url")),
      );
    }
  }
}

String _normalizeUrl(String raw) {
  final t = raw.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  return 'https://$t';
}

class _LinkDismiss extends StatelessWidget {
  final SavedLink link;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _LinkDismiss({required this.link, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Dismissible(
      key: ValueKey(link.id),
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
        title: 'Delete link?',
        message: link.title,
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: AppCard(theme: theme, pad: 14, onTap: onTap, child: Row(children: [
          IconChip(
            bg: theme.accent.withOpacity(0.13), size: 40,
            child: Icon(LucideIcons.link, color: theme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(link.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.1)),
              const SizedBox(height: 2),
              Text(link.url,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.muted)),
            ],
          )),
          Icon(LucideIcons.externalLink, color: theme.muted, size: 15),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'edit') {
                onEdit();
              } else if (val == 'delete') {
                final ok = await confirmDelete(context, title: 'Delete link?', message: link.title);
                if (ok) onDelete();
              }
            },
            icon: Icon(LucideIcons.moreVertical, size: 18, color: theme.muted),
            padding: EdgeInsets.zero,
            color: theme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [
                Icon(LucideIcons.pencil, size: 16, color: theme.ink),
                const SizedBox(width: 10),
                Text('Edit', style: TextStyle(color: theme.ink, fontSize: 14)),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(LucideIcons.trash2, size: 16, color: theme.danger),
                const SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: theme.danger, fontSize: 14)),
              ])),
            ],
          ),
        ])),
      ),
    );
  }
}

class _LinkSheet extends StatefulWidget {
  final SavedLink? link;
  const _LinkSheet({this.link});

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  late final TextEditingController _title;
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.link?.title ?? '');
    _url = TextEditingController(text: widget.link?.url ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppState>().theme;
    final isEdit = widget.link != null;
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
          Text(isEdit ? 'Edit link' : 'New link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 16),

          _field(theme, _title, 'Title', LucideIcons.tag, autofocus: !isEdit),
          const SizedBox(height: 10),
          _field(theme, _url, 'https://example.com', LucideIcons.link, keyboard: TextInputType.url),
          const SizedBox(height: 22),

          GestureDetector(
            onTap: () {
              final title = _title.text.trim();
              final url = _url.text.trim();
              if (title.isEmpty || url.isEmpty) return;
              final state = context.read<AppState>();
              if (isEdit) {
                state.editLink(widget.link!.copyWith(title: title, url: url));
              } else {
                state.addLink(title: title, url: url);
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
              child: Text(isEdit ? 'Save changes' : 'Save link',
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(theme, TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard, bool autofocus = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.muted),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: c,
          autofocus: autofocus,
          keyboardType: keyboard,
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
}
