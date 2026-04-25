import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/debt.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/segmented.dart';
import '../widgets/confirm_sheet.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String tab = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final debts = state.debts;
    final active = debts.where((d) => !d.settled).toList();
    final iOwe = active.where((d) => d.type == DebtType.iOwe).fold<int>(0, (s, d) => s + d.remain);
    final owedMe = active.where((d) => d.type == DebtType.theyOwe).fold<int>(0, (s, d) => s + d.remain);
    final net = owedMe - iOwe;
    final cur = state.profile.currencySymbol;
    final shown = tab == 'all'
        ? debts
        : debts.where((d) => (tab == 'i_owe' && d.type == DebtType.iOwe) || (tab == 'they_owe' && d.type == DebtType.theyOwe)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Finance', title: 'Debts & money'),
          right: [
            HeaderBtn(theme: theme, icon: LucideIcons.plus, onTap: () => _openDebtSheet(context)),
          ],
        ),

        // Prominent add button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GestureDetector(
            onTap: () => _openDebtSheet(context),
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
                Text('Log a debt', style: TextStyle(color: theme.accent, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),

        // Net position card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: net >= 0
                      ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
                      : [theme.accent, theme.accent2],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Net position', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${net >= 0 ? '+' : '−'}$cur${_fmt(net.abs())}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('You owe', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text('$cur${_fmt(iOwe)}', style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700)),
                  ])),
                  Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(width: 20),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Owed to you', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text('$cur${_fmt(owedMe)}', style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700)),
                  ])),
                ]),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Segmented<String>(
            theme: theme, value: tab,
            onChanged: (v) => setState(() => tab = v),
            items: const [
              MapEntry('all', 'All'),
              MapEntry('i_owe', 'I owe'),
              MapEntry('they_owe', 'Owed me'),
            ],
          ),
        ),
        const SizedBox(height: 22),

        if (debts.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 32,
              child: Column(children: [
                Icon(LucideIcons.wallet, size: 40, color: theme.muted),
                const SizedBox(height: 12),
                Text('No debts recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.ink)),
                const SizedBox(height: 6),
                Text('Tap + to log money owed or owing', style: TextStyle(fontSize: 13, color: theme.muted)),
              ]),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHead(theme: theme, title: 'Accounts'),
          ),
          const SizedBox(height: 12),
          for (final d in shown)
            _DismissibleDebt(
              debt: d, theme: theme,
              onPay: () => _openPaySheet(d),
              onEdit: () => _openDebtSheet(context, debt: d),
              onDelete: () => state.deleteDebt(d.id),
            ),
        ],
      ],
    );
  }

  Future<void> _openDebtSheet(BuildContext context, {Debt? debt}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _DebtSheet(debt: debt),
    );
  }

  Future<void> _openPaySheet(Debt d) async {
    final state = context.read<AppState>();
    final theme = state.theme;
    final cur = state.profile.currencySymbol;
    int amt = (d.remain * 0.25).round().clamp(1, d.remain);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final remain = d.remain;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.rule, width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Text('Log payment to', style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(d.person, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.ink)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Text(cur, style: TextStyle(fontSize: 26, color: theme.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    key: ValueKey(amt),
                    initialValue: amt.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => amt = int.tryParse(v) ?? 0,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -0.5),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  )),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                for (final q in [500, 1000, 2000, remain])
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(right: q == remain ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => set(() => amt = q),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: amt == q ? theme.accent : theme.bg,
                          border: Border.all(color: amt == q ? theme.accent : theme.rule, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          q == remain ? 'Full' : '$cur$q',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: amt == q ? Colors.white : theme.ink),
                        ),
                      ),
                    ),
                  )),
              ]),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  context.read<AppState>().payDebt(d.id, amt);
                  Navigator.of(ctx).pop();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: theme.glow, blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  alignment: Alignment.center,
                  child: Text('Log $cur${_fmt(amt)}', style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

// ── Dismissible debt card ─────────────────────────────────────────────────────

class _DismissibleDebt extends StatelessWidget {
  final Debt debt;
  final AppTheme theme;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DismissibleDebt({required this.debt, required this.theme, required this.onPay, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(debt.id),
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
        title: 'Delete debt?',
        message: debt.person,
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _DebtCard(debt: debt, theme: theme, onPay: onPay, onEdit: onEdit, onDelete: onDelete),
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final AppTheme theme;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DebtCard({required this.debt, required this.theme, required this.onPay, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final mine = debt.type == DebtType.iOwe;
    final cur = context.watch<AppState>().profile.currencySymbol;
    return AppCard(theme: theme, pad: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: mine ? theme.danger.withOpacity(0.12) : theme.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(debt.person[0].toUpperCase(),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: mine ? theme.danger : theme.success)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(debt.person, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.2), overflow: TextOverflow.ellipsis)),
            Row(children: [
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.pencil, size: 15, color: theme.muted),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.trash2, size: 15, color: theme.danger),
                ),
              ),
              Text(
                debt.settled ? 'Settled' : '$cur${_fmt(debt.remain)}',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: debt.settled ? theme.muted : theme.ink,
                  decoration: debt.settled ? TextDecoration.lineThrough : null,
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 2),
          Text('${debt.note} · due ${debt.due}', style: TextStyle(fontSize: 12, color: theme.muted)),
          if (!debt.settled) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(height: 4, child: Stack(children: [
                Container(color: theme.surface2),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  widthFactor: debt.pct.clamp(0.0, 1.0),
                  child: Container(color: mine ? theme.danger : theme.success),
                ),
              ])),
            ),
          ],
        ])),
      ]),
      if (!debt.settled) ...[
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPay,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(mine ? 'Make a payment' : 'Log a repayment',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.ink)),
          ),
        ),
      ],
    ]));
  }
}

// ── Add / Edit debt sheet ─────────────────────────────────────────────────────

class _DebtSheet extends StatefulWidget {
  final Debt? debt;
  const _DebtSheet({this.debt});

  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  late final TextEditingController _person;
  late final TextEditingController _total;
  late final TextEditingController _due;
  late final TextEditingController _note;
  late DebtType _type;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _person = TextEditingController(text: d?.person ?? '');
    _total = TextEditingController(text: d?.total.toString() ?? '');
    _due = TextEditingController(text: d?.due ?? '');
    _note = TextEditingController(text: d?.note ?? '');
    _type = d?.type ?? DebtType.iOwe;
  }

  @override
  void dispose() {
    _person.dispose();
    _total.dispose();
    _due.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = state.theme;
    final editing = widget.debt != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.rule, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text(editing ? 'Edit debt' : 'New debt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(height: 18),

          // Type toggle
          Row(children: [
            for (final t in DebtType.values)
              Expanded(child: Padding(
                padding: EdgeInsets.only(right: t == DebtType.iOwe ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == t ? theme.accent : theme.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _type == t ? theme.accent : theme.rule, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t == DebtType.iOwe ? 'I owe' : 'They owe me',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: _type == t ? Colors.white : theme.ink),
                    ),
                  ),
                ),
              )),
          ]),
          const SizedBox(height: 12),

          _FieldRow(theme: theme, hint: 'Person / lender name', controller: _person, autofocus: !editing),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _FieldRow(theme: theme, hint: 'Amount (${state.profile.currencySymbol})', controller: _total, keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _FieldRow(theme: theme, hint: 'Due date (e.g. Jun 12)', controller: _due)),
          ]),
          const SizedBox(height: 10),
          _FieldRow(theme: theme, hint: 'Note (optional)', controller: _note),
          const SizedBox(height: 22),

          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: theme.glow, blurRadius: 28, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: Text(editing ? 'Save changes' : 'Add debt',
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  void _submit() {
    if (_person.text.trim().isEmpty) return;
    final total = int.tryParse(_total.text.trim()) ?? 0;
    if (total <= 0) return;
    final state = context.read<AppState>();
    if (widget.debt != null) {
      state.editDebt(widget.debt!.copyWith(
        person: _person.text.trim(),
        type: _type,
        total: total,
        due: _due.text.trim().isEmpty ? '—' : _due.text.trim(),
        note: _note.text.trim(),
      ));
    } else {
      state.addDebt(
        person: _person.text.trim(),
        type: _type,
        total: total,
        due: _due.text.trim().isEmpty ? '—' : _due.text.trim(),
        note: _note.text.trim(),
      );
    }
    Navigator.of(context).pop();
  }
}

class _FieldRow extends StatelessWidget {
  final AppTheme theme;
  final String hint;
  final TextEditingController controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  const _FieldRow({required this.theme, required this.hint, required this.controller, this.autofocus = false, this.keyboardType});

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

String _fmt(int n) {
  if (n < 0) n = -n;
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}
