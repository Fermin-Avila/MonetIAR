// lib/features/finance/domain/finance_repository.dart
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/installment_plan.dart';
import 'package:monetiar/features/finance/domain/month_summary.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';

abstract interface class FinanceRepository {
  Future<List<Category>> categories();
  Future<List<Wallet>> wallets();
  Future<List<Transaction>> transactions(DateTime month);
  Future<List<InstallmentPlan>> installmentPlans(DateTime month);
  Future<List<MonthSummary>> previousMonths(DateTime month);
  Future<Transaction> addTransaction(Transaction t);
  Future<Transaction> updateTransaction(Transaction t);
  Future<void> deleteTransaction(String id);
  Future<void> setTransactionPaid(String id, bool paid);
}