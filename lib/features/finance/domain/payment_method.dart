// lib/features/finance/domain/payment_method.dart
enum PaymentMethod {
  debit('Débito'),
  credit('Crédito'),
  transfer('Transferencia'),
  cash('Efectivo'),
  qr('QR'),
  additional('Adicional');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod fromDb(String v) => PaymentMethod.values
      .firstWhere((e) => e.name == v, orElse: () => PaymentMethod.additional);
}