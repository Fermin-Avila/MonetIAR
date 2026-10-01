// lib/features/transactions/application/transaction_actions.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/dashboard/application/dashboard_providers.dart';
import 'package:monetiar/features/finance/application/finance_providers.dart';
import 'package:monetiar/features/finance/domain/finance_repository.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';

final transactionActionsProvider = Provider<TransactionActions>(TransactionActions.new);

/// Escribe en el repositorio y refresca todo lo que depende de los movimientos
/// (lista, saldos de cuentas calculados por el trigger y Resumen).
class TransactionActions {
  TransactionActions(this._ref);
  final Ref _ref;

  FinanceRepository get _repo => _ref.read(financeRepositoryProvider);

  void _refresh() {
    _ref.invalidate(monthTransactionsProvider);
    _ref.invalidate(walletsProvider);
    _ref.invalidate(dashboardProvider);
  }

  Future<void> save(Transaction t, {required bool isNew}) async {
    if (isNew) {
      await _repo.addTransaction(t);
    } else {
      await _repo.updateTransaction(t);
    }
    _refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteTransaction(id);
    _refresh();
  }

  Future<void> setPaid(String id, bool paid) async {
    await _repo.setTransactionPaid(id, paid);
    _refresh();
  }
}