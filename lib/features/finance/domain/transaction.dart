// lib/features/finance/domain/transaction.dart
import 'package:flutter/foundation.dart';
import 'package:monetiar/features/finance/domain/payment_method.dart';

enum TransactionType { income, expense }

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.date,
    this.categoryId,
    this.isPaid = true,
    this.walletId,
    this.note,
  });

  final String id;
  final String title; // "Motivo"
  final double amount; // "Importe"
  final TransactionType type;
  final String? categoryId;
  final PaymentMethod paymentMethod; // "Medio Pago"
  final DateTime date; // "Fecha [Limite / Pago]"
  final bool isPaid; // "Pago"
  final String? walletId;
  final String? note;

  bool get isExpense => type == TransactionType.expense;

  /// Columna "Resta" del XLSX.
  double get pendingAmount => isPaid ? 0 : amount;

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    PaymentMethod? paymentMethod,
    DateTime? date,
    bool? isPaid,
    String? walletId,
    String? note,
  }) =>
      Transaction(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        date: date ?? this.date,
        isPaid: isPaid ?? this.isPaid,
        walletId: walletId ?? this.walletId,
        note: note ?? this.note,
      );

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        type: TransactionType.values.byName(j['type'] as String),
        categoryId: j['category_id'] as String?,
        paymentMethod: PaymentMethod.fromDb(j['payment_method'] as String),
        date: DateTime.parse(j['date'] as String),
        isPaid: j['is_paid'] as bool? ?? true,
        walletId: j['wallet_id'] as String?,
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category_id': categoryId,
        'payment_method': paymentMethod.name,
        'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'is_paid': isPaid,
        'wallet_id': walletId,
        'note': note,
      };
}