// lib/features/finance/application/finance_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/finance/data/mock_finance_repository.dart';
import 'package:monetiar/features/finance/domain/finance_repository.dart';
import 'package:monetiar/core/config/env.dart';
import 'package:monetiar/features/auth/application/auth_providers.dart';
import 'package:monetiar/features/finance/data/supabase_finance_repository.dart';
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';

/// Punto único de inyección: al pasar a Supabase solo cambia esta línea.
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  if (Env.useMock) return MockFinanceRepository();
  return SupabaseFinanceRepository(ref.watch(supabaseClientProvider));
});

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void select(DateTime month) => state = DateTime(month.year, month.month);
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);
    
final categoriesProvider = FutureProvider.autoDispose<List<Category>>(
    (ref) => ref.watch(financeRepositoryProvider).categories());

final walletsProvider = FutureProvider.autoDispose<List<Wallet>>(
    (ref) => ref.watch(financeRepositoryProvider).wallets());

final monthTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(financeRepositoryProvider).transactions(month);
});