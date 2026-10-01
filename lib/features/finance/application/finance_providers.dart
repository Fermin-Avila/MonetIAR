// lib/features/finance/application/finance_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/finance/data/mock_finance_repository.dart';
import 'package:monetiar/features/finance/domain/finance_repository.dart';

/// Punto único de inyección: al pasar a Supabase solo cambia esta línea.
final financeRepositoryProvider =
    Provider<FinanceRepository>((ref) => MockFinanceRepository());

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