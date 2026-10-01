// lib/features/dashboard/presentation/dashboard_screen.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/core/theme/app_theme.dart';
import 'package:monetiar/core/utils/formatters.dart';
import 'package:monetiar/features/dashboard/application/dashboard_providers.dart';
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/month_summary.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';
import 'package:monetiar/features/finance/presentation/category_icons.dart';
import 'package:monetiar/core/config/env.dart';
import 'package:monetiar/features/auth/application/auth_providers.dart';
import 'package:monetiar/features/finance/presentation/month_selector.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    return Scaffold(
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator(radius: 14)),
        error: (e, _) => _ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => _DashboardView(data: data),
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gap = SizedBox(height: 24);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text('Resumen'),
          automaticallyImplyLeading: false,
          border: null,
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
          trailing: const MonthSelector(),
          leading: Env.useMock
            ? null
            : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
              child: const Icon(CupertinoIcons.square_arrow_right, size: 22),
              ),
        ),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            await ref.read(dashboardProvider.future);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          sliver: SliverList.list(children: [
            _BalanceCard(data: data),
            gap,
            const _SectionTitle('Cuentas'),
            _WalletsRow(wallets: data.wallets),
            gap,
            const _SectionTitle('Gastos por categoría'),
            _CategoryDonut(data: data),
            gap,
            const _SectionTitle('Sueldo vs. gastado'),
            _MonthlyBars(history: data.history),
            gap,
            const _SectionTitle('Cuotas y financiaciones'),
            _InstallmentsCard(data: data),
            gap,
            const _SectionTitle('Movimientos'),
            _MovementsSection(data: data),
          ]),
        ),
      ],
    );
  }
}

// ───────────────────────── Base ─────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            CupertinoButton.filled(onPressed: onRetry, child: const Text('Reintentar')),
          ]),
        ),
      );
}

// ───────────────────────── Balance ─────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final negative = data.balanceAfterAll < 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: negative
              ? const [Color(0xFFFF453A), Color(0xFFB3261E)]
              : const [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Disponible tras pagar todo',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: data.balanceAfterAll),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Text(
            Fmt.money(v),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Mientras pago: ${Fmt.money(data.balanceSoFar)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: data.spentRatio,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text('${(data.spentRatio * 100).round()}% del ingreso comprometido',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          _Stat(label: 'En cuentas', value: data.walletsAvailable),
          _Stat(label: 'Ingresos', value: data.income),
          _Stat(label: 'Pagado', value: data.paidExpenses),
          _Stat(label: 'Pendiente', value: data.pendingExpenses),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(Fmt.compact(value),
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ───────────────────────── Cuentas ─────────────────────────

IconData _walletIcon(WalletType t) => switch (t) {
      WalletType.bank => Icons.account_balance_rounded,
      WalletType.virtual => Icons.phone_iphone_rounded,
      WalletType.cash => Icons.payments_rounded,
      WalletType.creditCard => Icons.credit_card_rounded,
      WalletType.investment => Icons.trending_up_rounded,
    };

class _WalletsRow extends StatelessWidget {
  const _WalletsRow({required this.wallets});
  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          itemCount: wallets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _WalletTile(wallet: wallets[i]),
        ),
      );
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCard = wallet.type == WalletType.creditCard;
    final limit = wallet.creditLimit;
    final usage = isCard && limit != null && limit > 0
        ? (wallet.balance / limit).clamp(0.0, 1.0).toDouble()
        : null;

    return SizedBox(
      width: 164,
      child: _SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(_walletIcon(wallet.type), size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                Fmt.money(isCard ? (wallet.availableCredit ?? 0) : wallet.balance),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(isCard ? 'Disponible' : 'Saldo',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              if (usage != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: usage, minHeight: 5),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Gastos por categoría ─────────────────────────

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final slices = data.expenseSlices;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return _SurfaceCard(
      child: Column(children: [
        SizedBox(
          height: 180,
          child: Stack(alignment: Alignment.center, children: [
            PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              startDegreeOffset: -90,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.amount,
                    color: Color(s.category.colorValue),
                    radius: 24,
                    showTitle: false,
                  ),
              ],
            )),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Gastado', style: TextStyle(fontSize: 12, color: muted)),
              Text(Fmt.compact(data.expenses),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 14, runSpacing: 8, children: [
          for (final s in slices)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: Color(s.category.colorValue), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('${s.category.name} ${(s.share * 100).round()}%',
                  style: const TextStyle(fontSize: 13)),
            ]),
        ]),
      ]),
    );
  }
}

// ───────────────────────── Sueldo vs gastado ─────────────────────────

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.history});
  final List<MonthSummary> history;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = history.fold<double>(
            0, (m, e) => math.max(m, math.max(e.income, e.expenses))) *
        1.15;
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return _SurfaceCard(
      child: Column(children: [
        SizedBox(
          height: 190,
          child: BarChart(BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: hidden,
              topTitles: hidden,
              rightTitles: hidden,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      Fmt.monthShort(history[value.toInt()].month),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < history.length; i++)
                BarChartGroupData(x: i, barsSpace: 4, barRods: [
                  BarChartRodData(
                    toY: history[i].income,
                    width: 10,
                    color: AppTheme.income,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: history[i].expenses,
                    width: 10,
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ]),
            ],
          )),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegendDot(color: AppTheme.income, label: 'Sueldo'),
          const SizedBox(width: 20),
          _LegendDot(color: cs.primary, label: 'Gastado'),
        ]),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]);
}

// ───────────────────────── Cuotas ─────────────────────────

class _InstallmentsCard extends StatelessWidget {
  const _InstallmentsCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final projection = data.installmentProjection(4);
    final maxV = projection.fold<double>(0, math.max);

    return _SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _KeyValue(label: 'Deuda restante', value: Fmt.money(data.installmentDebt)),
          _KeyValue(label: 'Cuota mensual', value: Fmt.money(data.installmentMonthly)),
        ]),
        const Divider(height: 28),
        Text('Proyección próximos 4 meses',
            style: TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 10),
        for (var i = 0; i < projection.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                width: 40,
                child: Text(
                  Fmt.monthShort(DateTime(data.month.year, data.month.month + 1 + i)),
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxV == 0 ? 0 : projection[i] / maxV,
                    minHeight: 8,
                  ),
                ),
              ),
              SizedBox(
                width: 76,
                child: Text(Fmt.compact(projection[i]),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ]),
      );
}

// ───────────────────────── Movimientos ─────────────────────────

class _MovementsSection extends StatefulWidget {
  const _MovementsSection({required this.data});
  final DashboardData data;

  @override
  State<_MovementsSection> createState() => _MovementsSectionState();
}

class _MovementsSectionState extends State<_MovementsSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final showPending = _tab == 1;
    final items = showPending ? data.pendingTransactions : data.recentTransactions;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _tab,
          onValueChanged: (v) => setState(() => _tab = v ?? 0),
          children: const {
            0: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Últimos')),
            1: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Por pagar')),
          },
        ),
      ),
      if (showPending) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Total pendiente: ${Fmt.money(data.pendingExpenses)}',
              style: TextStyle(fontSize: 13, color: muted)),
        ),
      ],
      const SizedBox(height: 12),
      _SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(_tab),
            children: items.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Sin movimientos', style: TextStyle(color: muted)),
                    ),
                  ]
                : [
                    for (var i = 0; i < items.length; i++) ...[
                      _TransactionTile(
                        tx: items[i],
                        category: data.categoryOf(items[i]),
                        showDue: showPending,
                      ),
                      if (i < items.length - 1) const Divider(height: 1, indent: 68),
                    ],
                  ],
          ),
        ),
      ),
    ]);
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx, required this.category, this.showDue = false});
  final Transaction tx;
  final Category category;
  final bool showDue;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final isIncome = !tx.isExpense;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
          child: Icon(categoryIcon(category.iconKey), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              '${category.name} · ${tx.paymentMethod.label} · '
              '${showDue ? 'Vence ' : ''}${Fmt.dayMonth(tx.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          '${isIncome ? '+' : '−'} ${Fmt.money(tx.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isIncome ? AppTheme.income : null,
          ),
        ),
      ]),
    );
  }
}