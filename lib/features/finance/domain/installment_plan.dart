// lib/features/finance/domain/installment_plan.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Filas de las hojas "Tarjeta" y "Financiaciones".
@immutable
class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.title,
    required this.entity,
    required this.purchaseDate,
    required this.total,
    required this.installments,
    required this.paidInstallments,
    required this.nextDueDate,
    this.walletId,
  });

  final String id;
  final String title; // "Motivo"
  final String entity; // "TC Provincia", "Estancias"...
  final DateTime purchaseDate;
  final double total;
  final int installments; // "Cuotas"
  final int paidInstallments; // "Pagas"
  final DateTime nextDueDate; // "Próx. Venc."
  final String? walletId;

  int get remaining => math.max(installments - paidInstallments, 0); // "Restan"
  bool get isSettled => remaining == 0;
  double get monthlyAmount => isSettled ? 0 : total / installments; // "Cuota mensual"
  double get remainingDebt => remaining * monthlyAmount; // "Deuda Restante"

  /// Proyección del XLSX: en el mes +n paga si todavía restan más de n cuotas.
  double installmentDueAt(int monthsAhead) =>
      remaining > monthsAhead ? monthlyAmount : 0;

  InstallmentPlan copyWith({int? paidInstallments, DateTime? nextDueDate}) =>
      InstallmentPlan(
        id: id,
        title: title,
        entity: entity,
        purchaseDate: purchaseDate,
        total: total,
        installments: installments,
        paidInstallments: paidInstallments ?? this.paidInstallments,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        walletId: walletId,
      );

  factory InstallmentPlan.fromJson(Map<String, dynamic> j) => InstallmentPlan(
        id: j['id'] as String,
        title: j['title'] as String,
        entity: j['entity'] as String,
        purchaseDate: DateTime.parse(j['purchase_date'] as String),
        total: (j['total'] as num).toDouble(),
        installments: j['installments'] as int,
        paidInstallments: j['paid_installments'] as int,
        nextDueDate: DateTime.parse(j['next_due_date'] as String),
        walletId: j['wallet_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'entity': entity,
        'purchase_date': purchaseDate.toIso8601String(),
        'total': total,
        'installments': installments,
        'paid_installments': paidInstallments,
        'next_due_date': nextDueDate.toIso8601String(),
        'wallet_id': walletId,
      };
}