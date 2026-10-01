// lib/features/transactions/application/movement_filters.dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/features/finance/domain/payment_method.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';

enum MovementKind { all, expense, income, pending }

@immutable
class MovementFilters {
  const MovementFilters({
    this.query = '',
    this.kind = MovementKind.all,
    this.categoryId,
    this.method,
  });

  final String query;
  final MovementKind kind;
  final String? categoryId;
  final PaymentMethod? method;

  bool get isActive =>
      query.isNotEmpty || kind != MovementKind.all || categoryId != null || method != null;

  bool matches(Transaction t) {
    final kindOk = switch (kind) {
      MovementKind.all => true,
      MovementKind.expense => t.isExpense,
      MovementKind.income => !t.isExpense,
      MovementKind.pending => !t.isPaid,
    };
    if (!kindOk) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (method != null && t.paymentMethod != method) return false;
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false);
  }
}

class MovementFiltersNotifier extends Notifier<MovementFilters> {
  @override
  MovementFilters build() => const MovementFilters();

  void setQuery(String q) => state = MovementFilters(
      query: q, kind: state.kind, categoryId: state.categoryId, method: state.method);

  void setKind(MovementKind k) => state = MovementFilters(
      query: state.query, kind: k, categoryId: state.categoryId, method: state.method);

  void toggleCategory(String id) => state = MovementFilters(
      query: state.query,
      kind: state.kind,
      categoryId: state.categoryId == id ? null : id,
      method: state.method);

  void toggleMethod(PaymentMethod m) => state = MovementFilters(
      query: state.query,
      kind: state.kind,
      categoryId: state.categoryId,
      method: state.method == m ? null : m);

  void clear() => state = const MovementFilters();
}

final movementFiltersProvider =
    NotifierProvider<MovementFiltersNotifier, MovementFilters>(MovementFiltersNotifier.new);