// lib/features/transactions/presentation/movements_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/core/theme/app_theme.dart';
import 'package:monetiar/core/utils/formatters.dart';
import 'package:monetiar/features/dashboard/application/dashboard_providers.dart';
import 'package:monetiar/features/finance/application/finance_providers.dart';
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/payment_method.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';
import 'package:monetiar/features/finance/presentation/month_selector.dart';
import 'package:monetiar/features/transactions/application/movement_filters.dart';
import 'package:monetiar/features/transactions/application/transaction_actions.dart';
import 'package:monetiar/features/transactions/presentation/transaction_form.dart';
import 'package:monetiar/features/transactions/presentation/transaction_tile.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  final _search = TextEditingController();
  final _hidden = <String>{}; // borrados localmente, pendientes de confirmar

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(movementFiltersProvider).query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openForm({Transaction? initial}) async {
    final categories = ref.read(categoriesProvider).asData?.value;
    final wallets = ref.read(walletsProvider).asData?.value;
    if (categories == null || wallets == null) {
      _toast('Cargando datos, probá de nuevo en un instante.');
      return;
    }
    await showTransactionForm(context,
        categories: categories, wallets: wallets, initial: initial);
  }

  Future<void> _togglePaid(Transaction t) async {
    try {
      await ref.read(transactionActionsProvider).setPaid(t.id, !t.isPaid);
    } catch (_) {
      if (mounted) _toast('No se pudo actualizar el movimiento.');
    }
  }

  void _deleteWithUndo(Transaction t) {
    final actions = ref.read(transactionActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _hidden.add(t.id));
    messenger.clearSnackBars();
    messenger
        .showSnackBar(SnackBar(
          content: Text('"${t.title}" eliminado'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              if (mounted) setState(() => _hidden.remove(t.id));
            },
          ),
        ))
        .closed
        .then((reason) async {
      if (reason == SnackBarClosedReason.action) return;
      try {
        await actions.delete(t.id);
      } catch (_) {
        if (mounted) {
          setState(() => _hidden.remove(t.id));
          _toast('No se pudo eliminar el movimiento.');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(monthTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final filters = ref.watch(movementFiltersProvider);
    final categories = categoriesAsync.asData?.value;
    final wallets = walletsAsync.asData?.value;

    Widget content;
    if (txs.hasError && !txs.hasValue) {
      content = _Message(
        icon: Icons.error_outline_rounded,
        text: 'No se pudieron cargar los movimientos.',
        action: TextButton(
          onPressed: () => ref.invalidate(monthTransactionsProvider),
          child: const Text('Reintentar'),
        ),
      );
    } else if (!txs.hasValue || categories == null || wallets == null) {
      content = const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    } else {
      final visible = txs.requireValue
          .where((t) => !_hidden.contains(t.id) && filters.matches(t))
          .toList();
      content = _MovementsList(
        items: visible,
        categories: categories,
        wallets: wallets,
        onOpen: (t) => _openForm(initial: t),
        onTogglePaid: _togglePaid,
        onDelete: _deleteWithUndo,
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Movimientos'),
            automaticallyImplyLeading: false,
            border: null,
            backgroundColor:
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _openForm(),
              child: const Icon(CupertinoIcons.add_circled_solid, size: 30),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(monthTransactionsProvider);
              ref.invalidate(walletsProvider);
              ref.invalidate(dashboardProvider);
              await ref.read(monthTransactionsProvider.future);
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverList.list(children: [
              _FiltersBar(categories: categories ?? const [], searchController: _search),
              const SizedBox(height: 16),
              content,
            ]),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Filtros ─────────────────────────

class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.categories, required this.searchController});
  final List<Category> categories;
  final TextEditingController searchController;

  static Widget _seg(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(movementFiltersProvider);
    final notifier = ref.read(movementFiltersProvider.notifier);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: MonthSelector()),
      const SizedBox(height: 8),
      CupertinoSearchTextField(
        controller: searchController,
        placeholder: 'Buscar por motivo o nota',
        onChanged: notifier.setQuery,
      ),
      const SizedBox(height: 12),
      CupertinoSlidingSegmentedControl<MovementKind>(
        groupValue: filters.kind,
        onValueChanged: (v) => notifier.setKind(v ?? MovementKind.all),
        children: {
          MovementKind.all: _seg('Todos'),
          MovementKind.expense: _seg('Gastos'),
          MovementKind.income: _seg('Ingresos'),
          MovementKind.pending: _seg('Por pagar'),
        },
      ),
      const SizedBox(height: 10),
      _ChipRow(children: [
        for (final c in categories)
          FilterChip(
            label: Text(c.name),
            selected: filters.categoryId == c.id,
            showCheckmark: false,
            onSelected: (_) => notifier.toggleCategory(c.id),
          ),
      ]),
      const SizedBox(height: 6),
      _ChipRow(children: [
        for (final m in PaymentMethod.values)
          FilterChip(
            label: Text(m.label),
            selected: filters.method == m,
            showCheckmark: false,
            onSelected: (_) => notifier.toggleMethod(m),
          ),
      ]),
      if (filters.isActive)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              searchController.clear();
              notifier.clear();
            },
            child: const Text('Limpiar filtros'),
          ),
        ),
    ]);
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => Center(child: children[i]),
        ),
      );
}

// ───────────────────────── Lista ─────────────────────────

class _MovementsList extends StatelessWidget {
  const _MovementsList({
    required this.items,
    required this.categories,
    required this.wallets,
    required this.onOpen,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final List<Transaction> items;
  final List<Category> categories;
  final List<Wallet> wallets;
  final void Function(Transaction) onOpen;
  final void Function(Transaction) onTogglePaid;
  final void Function(Transaction) onDelete;

  Category _categoryOf(Transaction t) => categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => DashboardData.uncategorized,
      );

  String? _walletName(Transaction t) {
    for (final w in wallets) {
      if (w.id == t.walletId) return w.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _Message(
        icon: Icons.receipt_long_rounded,
        text: 'Sin movimientos para mostrar.\nTocá + para cargar el primero.',
      );
    }

    final income = items.where((t) => !t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final expenses = items.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);

    final groups = <DateTime, List<Transaction>>{};
    for (final t in items) {
      groups.putIfAbsent(DateTime(t.date.year, t.date.month, t.date.day), () => []).add(t);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _TotalsBar(income: income, expenses: expenses),
      const SizedBox(height: 16),
      for (final day in days) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(Fmt.dayHeader(day),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Theme.of(context).cardColor,
            child: Column(children: [
              for (var i = 0; i < groups[day]!.length; i++) ...[
                _SwipeableTile(
                  tx: groups[day]![i],
                  category: _categoryOf(groups[day]![i]),
                  walletName: _walletName(groups[day]![i]),
                  onOpen: onOpen,
                  onTogglePaid: onTogglePaid,
                  onDelete: onDelete,
                ),
                if (i < groups[day]!.length - 1) const Divider(height: 1, indent: 68),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ]);
  }
}

class _SwipeableTile extends StatelessWidget {
  const _SwipeableTile({
    required this.tx,
    required this.category,
    required this.walletName,
    required this.onOpen,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final Transaction tx;
  final Category category;
  final String? walletName;
  final void Function(Transaction) onOpen;
  final void Function(Transaction) onTogglePaid;
  final void Function(Transaction) onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(tx.id),
      background: _SwipeBackground(
        color: AppTheme.income,
        icon: tx.isPaid ? Icons.undo_rounded : Icons.check_rounded,
        label: tx.isPaid ? 'Pendiente' : 'Pagado',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: AppTheme.expense,
        icon: Icons.delete_rounded,
        label: 'Eliminar',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onTogglePaid(tx);
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(tx),
      child: Material(
        color: Theme.of(context).cardColor,
        child: TransactionTile(
          tx: tx,
          category: category,
          walletName: walletName,
          onTap: () => onOpen(tx),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.income, required this.expenses});
  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final balance = income - expenses;
    Widget stat(String label, double v, {Color? color}) => Expanded(
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(Fmt.compact(v),
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ]),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        stat('Ingresos', income, color: AppTheme.income),
        stat('Gastos', expenses),
        stat('Balance', balance, color: balance < 0 ? AppTheme.expense : null),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ?action,
        ]),
      );
}