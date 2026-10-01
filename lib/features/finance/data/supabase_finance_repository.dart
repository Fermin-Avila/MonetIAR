// lib/features/finance/data/supabase_finance_repository.dart
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/finance_repository.dart';
import 'package:monetiar/features/finance/domain/installment_plan.dart';
import 'package:monetiar/features/finance/domain/month_summary.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// RLS filtra por usuario en el servidor: no hace falta enviar user_id.
class SupabaseFinanceRepository implements FinanceRepository {
  SupabaseFinanceRepository(this._db);
  final SupabaseClient _db;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<Category>> categories() async {
    final rows = await _db.from('categories').select().order('name');
    return rows.map(Category.fromJson).toList();
  }

  @override
  Future<List<Wallet>> wallets() async {
    final rows = await _db.from('wallets').select().order('name');
    return rows.map(Wallet.fromJson).toList();
  }

  @override
  Future<List<Transaction>> transactions(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await _db
        .from('transactions')
        .select()
        .gte('date', _date(start))
        .lt('date', _date(end))
        .order('date', ascending: false);
    return rows.map(Transaction.fromJson).toList();
  }

  @override
  Future<List<InstallmentPlan>> installmentPlans(DateTime month) async {
    final rows = await _db.from('installment_plans').select().order('next_due_date');
    return rows.map(InstallmentPlan.fromJson).toList();
  }

  @override
  Future<Transaction> addTransaction(Transaction t) async {
    final row =
        await _db.from('transactions').insert(t.toJson()..remove('id')).select().single();
    return Transaction.fromJson(row);
  }

  @override
  Future<Transaction> updateTransaction(Transaction t) async {
    final row = await _db
        .from('transactions')
        .update(t.toJson()..remove('id'))
        .eq('id', t.id)
        .select()
        .single();
    return Transaction.fromJson(row);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db.from('transactions').delete().eq('id', id);
  }

  @override
  Future<void> setTransactionPaid(String id, bool paid) async {
    await _db.from('transactions').update({'is_paid': paid}).eq('id', id);
  }

  @override
  Future<List<MonthSummary>> previousMonths(DateTime month) async {
    const count = 5;
    final from = DateTime(month.year, month.month - count);
    final until = DateTime(month.year, month.month);
    final rows = await _db
        .from('transactions')
        .select('type, amount, date')
        .gte('date', _date(from))
        .lt('date', _date(until));

    int key(DateTime d) => d.year * 12 + d.month;
    final income = <int, double>{};
    final expenses = <int, double>{};
    for (final r in rows) {
      final k = key(DateTime.parse(r['date'] as String));
      final amount = (r['amount'] as num).toDouble();
      final target = r['type'] == 'income' ? income : expenses;
      target[k] = (target[k] ?? 0) + amount;
    }

    return [
      for (var i = count; i >= 1; i--)
        () {
          final m = DateTime(month.year, month.month - i);
          return MonthSummary(
            month: m,
            income: income[key(m)] ?? 0,
            expenses: expenses[key(m)] ?? 0,
          );
        }(),
    ];
  }
}