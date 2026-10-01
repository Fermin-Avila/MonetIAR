// lib/features/finance/domain/wallet.dart
import 'package:flutter/foundation.dart';

enum WalletType { bank, virtual, cash, creditCard, investment }

@immutable
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.creditLimit,
    this.currency = 'ARS',
  });

  final String id;
  final String name;
  final WalletType type;

  /// Para `creditCard` es el monto utilizado; para el resto, el saldo.
  final double balance;
  final double? creditLimit; // "Limite" de la hoja Tarjeta
  final String currency;

  /// "Disponible" de la hoja Tarjeta.
  double? get availableCredit =>
      type == WalletType.creditCard && creditLimit != null ? creditLimit! - balance : null;

  Wallet copyWith({String? name, double? balance, double? creditLimit}) => Wallet(
        id: id,
        name: name ?? this.name,
        type: type,
        balance: balance ?? this.balance,
        creditLimit: creditLimit ?? this.creditLimit,
        currency: currency,
      );

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        id: j['id'] as String,
        name: j['name'] as String,
        type: WalletType.values.byName(j['type'] as String),
        balance: (j['balance'] as num).toDouble(),
        creditLimit: (j['credit_limit'] as num?)?.toDouble(),
        currency: j['currency'] as String? ?? 'ARS',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'credit_limit': creditLimit,
        'currency': currency,
      };
}