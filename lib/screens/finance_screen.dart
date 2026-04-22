import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/debt.dart';
import '../theme/app_theme.dart';
import '../widgets/header.dart';
import '../widgets/primitives.dart';
import '../widgets/segmented.dart';

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
    final shown = tab == 'all'
        ? debts
        : debts.where((d) => (tab == 'i_owe' && d.type == DebtType.iOwe) || (tab == 'they_owe' && d.type == DebtType.theyOwe)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: [
        AppHeader(theme: theme, greeting: const Greeting(sub: 'April 2026', title: 'Finance'),
            right: [HeaderBtn(theme: theme, icon: LucideIcons.trendingUp)]),

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Net position', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${net >= 0 ? '+' : '−'}₹${_fmt(net.abs())}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
                  const SizedBox(height: 18),
                  Container(height: 1, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You owe', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text('₹${_fmt(iOwe)}', style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    )),
                    Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 20),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Owed to you', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text('₹${_fmt(owedMe)}', style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    )),
                  ]),
                ],
              ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(theme: theme, title: 'Accounts'),
        ),
        const SizedBox(height: 12),
        for (final d in shown) Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _DebtCard(
            debt: d, theme: theme,
            onPay: () => _openPaySheet(d),
          ),
        ),
      ],
    );
  }

  Future<void> _openPaySheet(Debt d) async {
    final state = context.read<AppState>();
    final theme = state.theme;
    int amt = (d.remain * 0.25).round();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, set) {
          final remain = d.remain;
          return Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.rule, width: 1),
            ),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 36 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: theme.rule, borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 18),
                Text('Log payment to', style: TextStyle(fontSize: 13, color: theme.muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(d.person, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.ink)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Text('₹', style: TextStyle(fontSize: 26, color: theme.muted, fontWeight: FontWeight.w600)),
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
                            q == remain ? 'Full' : '₹$q',
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
                    child: Text('Log ₹${_fmt(amt)}', style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final AppTheme theme;
  final VoidCallback onPay;
  const _DebtCard({required this.debt, required this.theme, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final mine = debt.type == DebtType.iOwe;
    return AppCard(
      theme: theme, pad: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: mine ? theme.danger.withOpacity(0.12) : theme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(debt.person[0], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: mine ? theme.danger : theme.success)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Text(debt.person, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.ink, letterSpacing: -0.2), overflow: TextOverflow.ellipsis)),
                    Text(
                      debt.settled ? 'Settled' : '₹${_fmt(debt.remain)}',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: debt.settled ? theme.muted : theme.ink,
                        decoration: debt.settled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text('${debt.note} · due ${debt.due}', style: TextStyle(fontSize: 12, color: theme.muted)),
                  if (!debt.settled) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(children: [
                          Container(color: theme.surface2),
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            widthFactor: debt.pct.clamp(0.0, 1.0),
                            child: Container(color: mine ? theme.danger : theme.success),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
          if (!debt.settled) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  mine ? 'Make a payment' : 'Log a repayment',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.ink),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _fmt(int n) {
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
