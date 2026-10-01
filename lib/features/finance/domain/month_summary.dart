// lib/features/finance/domain/month_summary.dart
import 'package:flutter/foundation.dart';

/// Fila de la tabla Mes / Sueldo / Gastado / Diferencia del Dashboard.
@immutable
class MonthSummary {
  const MonthSummary({required this.month, required this.income, required this.expenses});

  final DateTime month;
  final double income;
  final double expenses;

  double get difference => income - expenses;
}