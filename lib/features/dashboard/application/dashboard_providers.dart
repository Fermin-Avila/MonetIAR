// lib/features/dashboard/application/dashboard_providers.dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/finance/application/finance_providers.dart';
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/installment_plan.dart';
import 'package:monetiar/features/finance/domain/month_summary.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';

@immutable
class CategorySlice {
  const CategorySlice({required this.category, required this.amount, required this.share});
  final Category category;
  final double amount;
  final double share;
}

@immutable
class DashboardData {
  const DashboardData({
    required this.month,
    required this.transactions,
    required this.categories,
    required this.wallets,
    required this.plans,
    required this.history,
  });

  final DateTime month;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Wallet> wallets;
  final List<InstallmentPlan> plans;
  final List<MonthSummary> history;

  static const uncategorized = Category(
      id: 'other', name: 'Sin categoría', iconKey: 'other', colorValue: 0xFF8E8E93);

  double _sum(Iterable<Transaction> t) => t.fold<double>(0, (s, e) => s + e.amount);

  double get income => _sum(transactions.where((t) => !t.isExpense));
  double get expenses => _sum(transactions.where((t) => t.isExpense));
  double get paidExpenses => _sum(transactions.where((t) => t.isExpense && t.isPaid));
  double get pendingExpenses => expenses - paidExpenses;

  /// "Tras pagar todo" del XLSX.
  double get balanceAfterAll => income - expenses;

  /// "Mientras pago" del XLSX.
  double get balanceSoFar => income - paidExpenses;

  double get spentRatio => income <= 0 ? 0 : (expenses / income).clamp(0.0, 1.0).toDouble();

  Category categoryOf(Transaction t) => categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => uncategorized,
      );

  List<CategorySlice> get expenseSlices {
    final totals = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      final k = categoryOf(t).id;
      totals[k] = (totals[k] ?? 0) + t.amount;
    }
    final total = expenses;
    final slices = [
      for (final e in totals.entries)
        CategorySlice(
          category: categories.firstWhere((c) => c.id == e.key, orElse: () => uncategorized),
          amount: e.value,
          share: total == 0 ? 0 : e.value / total,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return slices;
  }

  List<Transaction> get recentTransactions =>
      ([...transactions.where((t) => t.isPaid)]..sort((a, b) => b.date.compareTo(a.date)))
          .take(6)
          .toList();

  List<Transaction> get pendingTransactions =>
      [...transactions.where((t) => t.isExpense && !t.isPaid)]
        ..sort((a, b) => a.date.compareTo(b.date));

  double get installmentDebt => plans.fold<double>(0, (s, p) => s + p.remainingDebt);
  double get installmentMonthly => plans.fold<double>(0, (s, p) => s + p.monthlyAmount);

  List<double> installmentProjection(int months) => [
        for (var i = 0; i < months; i++)
          plans.fold<double>(0, (s, p) => s + p.installmentDueAt(i)),
      ];
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(financeRepositoryProvider);

  final (categories, transactions, wallets, plans, previous) = await (
    repo.categories(),
    repo.transactions(month),
    repo.wallets(),
    repo.installmentPlans(month),
    repo.previousMonths(month),
  ).wait;

  double sum(Iterable<Transaction> t) => t.fold<double>(0, (s, e) => s + e.amount);
  final current = MonthSummary(
    month: month,
    income: sum(transactions.where((t) => !t.isExpense)),
    expenses: sum(transactions.where((t) => t.isExpense)),
  );

  return DashboardData(
    month: month,
    transactions: transactions,
    categories: categories,
    wallets: wallets,
    plans: plans,
    history: [...previous, current],
  );
});