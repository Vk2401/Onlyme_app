import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final p = state.profile;

    final name = (p.name == null || p.name!.isEmpty) ? 'Set your name' : p.name!;
    final dobStr = (p.dob == null || p.dob!.isEmpty) ? 'Not set' : _formatDob(p.dob!);
    final phone = (p.phone == null || p.phone!.isEmpty) ? 'Not set' : p.phone!;
    final initial = (p.name != null && p.name!.isNotEmpty)
        ? p.name!.trim().substring(0, 1).toUpperCase()
        : '?';
    final totalEntries = state.tasks.length
        + state.debts.length
        + state.events.length
        + state.snapshots.values.fold<int>(0, (s, l) => s + l.length)
        + state.weightLogs.length;
    final since = DateTime.fromMillisecondsSinceEpoch(p.createdAt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Your details', title: 'Profile'),
          right: [
            HeaderBtn(
              theme: theme,
              icon: LucideIcons.edit3,
              onTap: () => _openEditSheet(context),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 20, child: Column(children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.accent, theme.accent2]),
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: Text(initial, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            Text(name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: (p.name == null || p.name!.isEmpty) ? theme.muted : theme.ink,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 4),
            Text('Since ${_monthYear(since)} · $totalEntries entries',
                style: TextStyle(fontSize: 13, color: theme.muted)),
          ])),
        ),

        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Text('DETAILS', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 1,
          )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(theme: theme, pad: 0, child: Column(children: [
            _DetailRow(icon: LucideIcons.user, label: 'Name', value: name, empty: p.name == null || p.name!.isEmpty),
            _DetailRow(icon: LucideIcons.calendar, label: 'Date of birth',
                value: p.age != null ? '$dobStr  ·  ${p.age} yrs' : dobStr,
                empty: p.dob == null || p.dob!.isEmpty, hasTop: true),
            _DetailRow(icon: LucideIcons.phone, label: 'Phone', value: phone,
                empty: p.phone == null || p.phone!.isEmpty, hasTop: true),
          ])),
        ),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => _openEditSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: Text(
                p.isEmpty ? 'Set up profile' : 'Edit profile',
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => state.setScreen('more'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.rule, width: 1),
              ),
              alignment: Alignment.center,
              child: Text('Back', style: TextStyle(fontSize: 14, color: theme.ink, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const _EditProfileSheet(),
    );
  }
}

String _monthYear(DateTime d) {
  const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${abbrs[d.month - 1]} ${d.year}';
}

String _formatDob(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${abbrs[d.month - 1]} ${d.day}, ${d.year}';
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool empty;
  final bool hasTop;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.empty,
    this.hasTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: hasTop ? BoxDecoration(border: Border(top: BorderSide(color: theme.rule, width: 1))) : null,
      child: Row(children: [
        IconChip(bg: theme.accent.withOpacity(0.13), size: 36, child: Icon(icon, color: theme.accent, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              empty ? 'Not set' : value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: empty ? theme.muted : theme.ink,
                letterSpacing: -0.1,
              ),
            ),
          ],
        )),
      ]),
    );
  }
}

// ── Edit sheet ───────────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _currency;
  DateTime? _dob;

  static const _presetCurrencies = ['₹', '\$', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _name = TextEditingController(text: p.name ?? '');
    _phone = TextEditingController(text: p.phone ?? '');
    _currency = TextEditingController(text: p.currencySymbol);
    _dob = (p.dob == null || p.dob!.isEmpty) ? null : DateTime.tryParse(p.dob!);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _currency.dispose();
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
          Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 4),
          Text('All fields optional', style: TextStyle(fontSize: 12, color: theme.muted)),
          const SizedBox(height: 18),

          _FieldLabel('Name', theme: theme),
          _TextFieldBox(theme: theme, controller: _name, hint: 'Your name', icon: LucideIcons.user),
          const SizedBox(height: 14),

          _FieldLabel('Date of birth', theme: theme),
          GestureDetector(
            onTap: _pickDate,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(LucideIcons.calendar, size: 18, color: theme.muted),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _dob == null ? 'Pick a date' : _formatDob(_dob!.toIso8601String()),
                  style: TextStyle(
                    fontSize: 15,
                    color: _dob == null ? theme.muted : theme.ink,
                    fontWeight: FontWeight.w500,
                  ),
                )),
                if (_dob != null)
                  GestureDetector(
                    onTap: () => setState(() => _dob = null),
                    child: Icon(LucideIcons.x, size: 16, color: theme.muted),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          _FieldLabel('Phone', theme: theme),
          _TextFieldBox(
            theme: theme, controller: _phone, hint: 'Phone number',
            icon: LucideIcons.phone,
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
          ),
          const SizedBox(height: 14),

          _FieldLabel('Currency symbol', theme: theme),
          Row(children: [
            for (final sym in _presetCurrencies) ...[
              _CurrencyChip(
                symbol: sym,
                selected: _currency.text.trim() == sym,
                onTap: () => setState(() => _currency.text = sym),
                theme: theme,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _currency,
                textAlign: TextAlign.center,
                maxLength: 3,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 15, color: theme.ink, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Custom',
                  hintStyle: TextStyle(color: theme.muted, fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 22),

          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.bg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.rule),
                ),
                alignment: Alignment.center,
                child: Text('Cancel', style: TextStyle(fontSize: 14, color: theme.ink, fontWeight: FontWeight.w600)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.accent, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: theme.glow, blurRadius: 22, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: const Text('Save', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _save() {
    final sym = _currency.text.trim();
    context.read<AppState>().updateProfile(
      name: _name.text,
      dob: _dob?.toIso8601String(),
      phone: _phone.text,
      currencySymbol: sym.isEmpty ? '₹' : sym,
    );
    Navigator.of(context).pop();
  }
}

class _CurrencyChip extends StatelessWidget {
  final String symbol;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;
  const _CurrencyChip({required this.symbol, required this.selected, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? theme.accent : theme.rule, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(symbol, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : theme.ink,
        )),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final AppTheme theme;
  const _FieldLabel(this.text, {required this.theme});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: theme.muted, letterSpacing: 0.3,
        )),
      );
}

class _TextFieldBox extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  const _TextFieldBox({
    required this.theme,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.muted),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formatters,
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
