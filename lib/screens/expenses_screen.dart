import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';

enum _Filter { week, month, year, all }

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  _Filter _filter = _Filter.month;

  List<Expense> _filtered(List<Expense> all) {
    final now = DateTime.now();
    return all.where((e) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      switch (_filter) {
        case _Filter.week:
          return now.difference(d).inDays < 7;
        case _Filter.month:
          return d.year == now.year && d.month == now.month;
        case _Filter.year:
          return d.year == now.year;
        case _Filter.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<_BarData> _chartBars(List<Expense> filtered) {
    final now = DateTime.now();
    switch (_filter) {
      case _Filter.week:
        return List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final total = filtered.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
            return d.year == day.year && d.month == day.month && d.day == day.day;
          }).fold(0, (s, e) => s + e.amount);
          const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
          return _BarData(labels[day.weekday - 1], total);
        });
      case _Filter.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final weeks = (daysInMonth / 7).ceil();
        return List.generate(weeks, (i) {
          final start = i * 7 + 1;
          final end = ((i + 1) * 7).clamp(1, daysInMonth);
          final total = filtered.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
            return d.day >= start && d.day <= end;
          }).fold(0, (s, e) => s + e.amount);
          return _BarData('W${i + 1}', total);
        });
      case _Filter.year:
        const labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        return List.generate(12, (i) {
          final total = filtered.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
            return d.month == i + 1;
          }).fold(0, (s, e) => s + e.amount);
          return _BarData(labels[i], total);
        });
      case _Filter.all:
        return List.generate(12, (i) {
          final m = DateTime(now.year, now.month - 11 + i);
          final total = filtered.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
            return d.year == m.year && d.month == m.month;
          }).fold(0, (s, e) => s + e.amount);
          const mo = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
          return _BarData(mo[m.month - 1], total);
        });
    }
  }

  Map<String, List<Expense>> _grouped(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<Expense>>{};
    for (final e in expenses) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      final day = DateTime(d.year, d.month, d.day);
      final String key;
      if (day == today) {
        key = 'Today';
      } else if (day == yesterday) {
        key = 'Yesterday';
      } else {
        key = e.dateStr;
      }
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  void _showAdd(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const _ExpenseSheet(),
    );
  }

  void _showEdit(BuildContext context, Expense e) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseSheet(editing: e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    final cur = state.profile.currencySymbol;
    final filtered = _filtered(state.expenses);
    final total = filtered.fold(0, (s, e) => s + e.amount);
    final bars = _chartBars(filtered);
    final grouped = _grouped(filtered);

    final filterLabel = switch (_filter) {
      _Filter.week => 'This week',
      _Filter.month => 'This month',
      _Filter.year => 'This year',
      _Filter.all => 'All time',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(
          theme: theme,
          greeting: const Greeting(sub: 'Track your spending', title: 'Expenses'),
          right: [HeaderBtn(theme: theme, icon: LucideIcons.plus, onTap: () => _showAdd(context))],
        ),

        // Prominent add button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: GestureDetector(
            onTap: () => _showAdd(context),
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
                Text('Log an expense', style: TextStyle(color: theme.accent, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),

        // Filter tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(children: [
            for (final f in _Filter.values) ...[
              if (f != _Filter.values.first) const SizedBox(width: 8),
              _FilterChip(
                label: switch (f) {
                  _Filter.week => 'Week',
                  _Filter.month => 'Month',
                  _Filter.year => 'Year',
                  _Filter.all => 'All',
                },
                selected: _filter == f,
                theme: theme,
                onTap: () => setState(() => _filter = f),
              ),
            ],
          ]),
        ),

        // Summary card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            theme: theme, pad: 20,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total spent', style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('$cur${_fmtAmount(total)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: theme.ink, letterSpacing: -1)),
                const SizedBox(height: 4),
                Text('$filterLabel · ${filtered.length} transactions',
                    style: TextStyle(fontSize: 12, color: theme.muted)),
              ])),
              IconChip(
                bg: theme.accent.withOpacity(0.12),
                size: 52,
                child: Icon(LucideIcons.receipt, color: theme.accent, size: 24),
              ),
            ]),
          ),
        ),

        // Bar chart
        if (bars.any((b) => b.amount > 0)) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Spending over time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.muted)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 100,
                  child: _BarChart(bars: bars, color: theme.accent),
                ),
              ]),
            ),
          ),
        ],

        // Category breakdown
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              theme: theme, pad: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('By category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.muted)),
                const SizedBox(height: 14),
                ..._buildCategoryRows(filtered, total, cur, theme),
              ]),
            ),
          ),
        ],

        // Transactions
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            theme: theme, title: 'Transactions',
            action: 'Add', onAction: () => _showAdd(context),
          ),
        ),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AppCard(
              theme: theme, pad: 28,
              child: Column(children: [
                Icon(LucideIcons.receipt, size: 36, color: theme.muted),
                const SizedBox(height: 10),
                Text('No expenses yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink)),
                const SizedBox(height: 4),
                Text('Tap + to log your first expense', style: TextStyle(fontSize: 13, color: theme.muted)),
              ]),
            ),
          )
        else
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 6),
              child: Row(children: [
                Text(entry.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: 0.3)),
                const Spacer(),
                Text(
                  '$cur${_fmtAmount(entry.value.fold(0, (s, e) => s + e.amount))}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(
                theme: theme, pad: 0,
                child: Column(children: [
                  for (var i = 0; i < entry.value.length; i++)
                    _ExpenseRow(
                      expense: entry.value[i],
                      hasTop: i > 0,
                      cur: cur,
                      theme: theme,
                      onEdit: () => _showEdit(context, entry.value[i]),
                      onDelete: () async {
                        final ok = await confirmDelete(context, title: 'Delete expense?',
                            message: '${entry.value[i].category} · $cur${_fmtAmount(entry.value[i].amount)}');
                        if (ok && context.mounted) {
                          context.read<AppState>().deleteExpense(entry.value[i].id);
                        }
                      },
                    ),
                ]),
              ),
            ),
          ],
      ],
    );
  }

  List<Widget> _buildCategoryRows(List<Expense> filtered, int total, String cur, AppTheme theme) {
    final map = <String, int>{};
    for (final e in filtered) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rows = <Widget>[];
    for (var i = 0; i < sorted.length; i++) {
      final cat = sorted[i].key;
      final amt = sorted[i].value;
      final pct = total == 0 ? 0.0 : amt / total;
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(_CategoryRow(cat: cat, amount: amt, pct: pct, cur: cur, theme: theme));
    }
    return rows;
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppTheme theme;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? theme.accent : theme.rule),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : theme.muted,
        )),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String cat;
  final int amount;
  final double pct;
  final String cur;
  final AppTheme theme;
  const _CategoryRow({required this.cat, required this.amount, required this.pct, required this.cur, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(cat);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(_catIcon(cat), size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.ink))),
        Text('$cur${_fmtAmount(amount)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.ink)),
        const SizedBox(width: 6),
        SizedBox(width: 34, child: Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 11, color: theme.muted), textAlign: TextAlign.right)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LayoutBuilder(builder: (_, box) => Stack(children: [
          Container(height: 5, width: box.maxWidth, color: theme.rule),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            height: 5, width: box.maxWidth * pct,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
        ])),
      ),
    ]);
  }
}

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final bool hasTop;
  final String cur;
  final AppTheme theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExpenseRow({required this.expense, required this.hasTop, required this.cur, required this.theme, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(expense.category);
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        color: theme.danger,
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) async => confirmDelete(context, title: 'Delete expense?',
          message: '${expense.category} · $cur${_fmtAmount(expense.amount)}'),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: hasTop ? BoxDecoration(border: Border(top: BorderSide(color: theme.rule, width: 1))) : null,
        child: Row(children: [
          IconChip(bg: color.withOpacity(0.13), size: 38,
              child: Icon(_catIcon(expense.category), color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense.category, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.ink)),
            if (expense.note.isNotEmpty)
              Text(expense.note, style: TextStyle(fontSize: 12, color: theme.muted), overflow: TextOverflow.ellipsis),
          ])),
          Text('$cur${_fmtAmount(expense.amount)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.ink)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.all(4), child: Icon(LucideIcons.pencil, size: 13, color: theme.muted)),
          ),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.all(4), child: Icon(LucideIcons.trash2, size: 13, color: theme.danger)),
          ),
        ]),
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarData {
  final String label;
  final int amount;
  const _BarData(this.label, this.amount);
}

class _BarChart extends StatelessWidget {
  final List<_BarData> bars;
  final Color color;
  const _BarChart({required this.bars, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) => CustomPaint(
      size: Size(box.maxWidth, box.maxHeight),
      painter: _BarChartPainter(bars: bars, color: color),
    ));
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_BarData> bars;
  final Color color;
  const _BarChartPainter({required this.bars, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final maxAmt = bars.map((b) => b.amount).fold(0, (a, b) => a > b ? a : b);
    if (maxAmt == 0) return;

    const labelH = 18.0;
    const padT = 4.0;
    const barGap = 5.0;
    final chartH = size.height - labelH - padT;
    final barW = size.width / bars.length;

    final barPaint = Paint()..color = color.withOpacity(0.85);
    final highlightPaint = Paint()..color = color;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < bars.length; i++) {
      final x = i * barW;
      final frac = bars[i].amount / maxAmt;
      final bH = (frac * chartH).clamp(3.0, chartH);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + barGap / 2, padT + chartH - bH, barW - barGap, bH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, bars[i].amount == maxAmt ? highlightPaint : barPaint);

      tp.text = TextSpan(
        text: bars[i].label,
        style: TextStyle(color: color.withOpacity(0.55), fontSize: 9, fontWeight: FontWeight.w600),
      );
      tp.layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, size.height - labelH + 4));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.bars != bars || old.color != color;
}

// ── Add / Edit sheet ──────────────────────────────────────────────────────────

class _ExpenseSheet extends StatefulWidget {
  final Expense? editing;
  const _ExpenseSheet({this.editing});
  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _amtCtrl;
  late final TextEditingController _noteCtrl;
  late String _cat;

  @override
  void initState() {
    super.initState();
    _amtCtrl = TextEditingController(text: widget.editing != null ? '${widget.editing!.amount}' : '');
    _noteCtrl = TextEditingController(text: widget.editing?.note ?? '');
    _cat = widget.editing?.category ?? kExpenseCategories.first;
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amt = int.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) return;
    final state = context.read<AppState>();
    if (widget.editing != null) {
      state.editExpense(widget.editing!.copyWith(amount: amt, category: _cat, note: _noteCtrl.text.trim()));
    } else {
      state.addExpense(amount: amt, category: _cat, note: _noteCtrl.text.trim());
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    final cur = context.read<AppState>().profile.currencySymbol;
    final editing = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(editing ? 'Edit expense' : 'Log expense',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.ink)),
          ),
          const SizedBox(height: 20),

          // Amount field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Amount ($cur)', style: TextStyle(fontSize: 11, color: theme.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: _amtCtrl,
                autofocus: !editing,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.ink),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(fontSize: 22, color: theme.muted, fontWeight: FontWeight.w700),
                  isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // Category chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Category', style: TextStyle(fontSize: 12, color: theme.muted, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final cat in kExpenseCategories)
              GestureDetector(
                onTap: () => setState(() => _cat = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _cat == cat ? _catColor(cat).withOpacity(0.18) : theme.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cat == cat ? _catColor(cat) : theme.rule),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_catIcon(cat), size: 13, color: _catColor(cat)),
                    const SizedBox(width: 5),
                    Text(cat, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _cat == cat ? _catColor(cat) : theme.muted,
                    )),
                  ]),
                ),
              ),
          ]),

          const SizedBox(height: 14),

          // Note field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Note (optional)', style: TextStyle(fontSize: 11, color: theme.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: _noteCtrl,
                style: TextStyle(fontSize: 15, color: theme.ink),
                decoration: InputDecoration(
                  hintText: 'e.g. Lunch at office',
                  hintStyle: TextStyle(color: theme.muted, fontSize: 15),
                  isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: theme.glow, blurRadius: 18, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: Text(editing ? 'Save changes' : 'Add expense',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _catColor(String cat) {
  switch (cat) {
    case 'Food': return const Color(0xFFF472B6);
    case 'Transport': return const Color(0xFF60A5FA);
    case 'Shopping': return const Color(0xFFFBBF24);
    case 'Entertainment': return const Color(0xFFA78BFA);
    case 'Health': return const Color(0xFF34D399);
    case 'Bills': return const Color(0xFFEF4444);
    case 'Education': return const Color(0xFF8B7CFF);
    default: return const Color(0xFF94A3B8);
  }
}

IconData _catIcon(String cat) {
  switch (cat) {
    case 'Food': return LucideIcons.utensils;
    case 'Transport': return LucideIcons.car;
    case 'Shopping': return LucideIcons.shoppingBag;
    case 'Entertainment': return LucideIcons.film;
    case 'Health': return LucideIcons.heart;
    case 'Bills': return LucideIcons.receipt;
    case 'Education': return LucideIcons.bookOpen;
    default: return LucideIcons.circle;
  }
}

String _fmtAmount(int n) {
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
