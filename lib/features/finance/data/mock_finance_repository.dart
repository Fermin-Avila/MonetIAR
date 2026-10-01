// lib/features/finance/data/mock_finance_repository.dart
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/finance_repository.dart';
import 'package:monetiar/features/finance/domain/installment_plan.dart';
import 'package:monetiar/features/finance/domain/month_summary.dart';
import 'package:monetiar/features/finance/domain/payment_method.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';

class MockFinanceRepository implements FinanceRepository {
  Future<T> _latency<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return value;
  }

  @override
  Future<List<Category>> categories() => _latency(const [
        Category(id: 'ingresos', name: 'Ingresos', iconKey: 'income', colorValue: 0xFF30D158),
        Category(id: 'casa', name: 'Casa', iconKey: 'home', colorValue: 0xFF0A84FF),
        Category(id: 'impuestos', name: 'Impuestos', iconKey: 'receipt', colorValue: 0xFF8E8E93),
        Category(id: 'comida', name: 'Comida', iconKey: 'restaurant', colorValue: 0xFFFF9F0A),
        Category(id: 'salud', name: 'Salud', iconKey: 'health', colorValue: 0xFFFF375F),
        Category(id: 'auto', name: 'Auto', iconKey: 'car', colorValue: 0xFF64D2FF),
        Category(id: 'ocio', name: 'Ocio', iconKey: 'leisure', colorValue: 0xFFBF5AF2),
        Category(id: 'subs', name: 'Subs', iconKey: 'subs', colorValue: 0xFF5E5CE6),
        Category(id: 'valen', name: 'Valen', iconKey: 'person', colorValue: 0xFFFF6482),
        Category(id: 'fer', name: 'Fer', iconKey: 'person', colorValue: 0xFF34C759),
        Category(id: 'tcredito', name: 'T Crédito', iconKey: 'card', colorValue: 0xFFFFD60A),
      ]);

  @override
  Future<List<Wallet>> wallets() => _latency(const [
        Wallet(id: 'w-bank', name: 'Cuenta principal', type: WalletType.bank, balance: 318450),
        Wallet(id: 'w-mp', name: 'Mercado Pago', type: WalletType.virtual, balance: 118475),
        Wallet(id: 'w-cocos', name: 'Cocos', type: WalletType.investment, balance: 1062391),
        Wallet(id: 'w-cash', name: 'Efectivo', type: WalletType.cash, balance: 45000),
        Wallet(
          id: 'w-tc',
          name: 'TC Provincia',
          type: WalletType.creditCard,
          balance: 646900,
          creditLimit: 1280000,
        ),
      ]);

  @override
  Future<List<Transaction>> transactions(DateTime month) {
    DateTime d(int day) => DateTime(month.year, month.month, day);
    var n = 0;
    Transaction e(String title, double amount, String cat, PaymentMethod pm, int day,
            {bool paid = true}) =>
        Transaction(
          id: 'tx-${n++}',
          title: title,
          amount: amount,
          type: TransactionType.expense,
          categoryId: cat,
          paymentMethod: pm,
          date: d(day),
          isPaid: paid,
        );

    const debit = PaymentMethod.debit;
    const transfer = PaymentMethod.transfer;

    return _latency([
      Transaction(
        id: 'tx-in-1',
        title: 'Sueldo',
        amount: 1591350,
        type: TransactionType.income,
        categoryId: 'ingresos',
        paymentMethod: transfer,
        date: d(1),
      ),
      Transaction(
        id: 'tx-in-2',
        title: 'Otros ingresos',
        amount: 148392.24,
        type: TransactionType.income,
        categoryId: 'ingresos',
        paymentMethod: transfer,
        date: d(5),
      ),
      e('Pago tarjeta', 630000, 'tcredito', debit, 2),
      e('ARCA', 75099.08, 'impuestos', debit, 20),
      e('Wifi', 38000, 'casa', transfer, 10, paid: false),
      e('Luz', 33900, 'casa', debit, 12, paid: false),
      e('Gas', 75991.69, 'casa', debit, 6, paid: false),
      e('Seguro auto', 35000, 'auto', PaymentMethod.cash, 10, paid: false),
      e('Garage', 60000, 'auto', transfer, 10, paid: false),
      e('Netflix', 11756, 'subs', debit, 6, paid: false),
      e('Spotify', 4308.79, 'subs', debit, 4, paid: false),
      e('iCloud', 5909.61, 'subs', debit, 11, paid: false),
      e('Amazon Video', 8000, 'subs', debit, 9, paid: false),
      e('Pilates', 46000, 'valen', transfer, 3),
      e('Mecánico', 80000, 'auto', transfer, 8),
      e('Cochera', 21600, 'auto', transfer, 7),
      e('YPF', 15000, 'auto', debit, 9),
      e('Canasta mate', 45000, 'casa', transfer, 5),
      e('Mostaza', 28090, 'comida', debit, 4),
      e('Kiosco', 5800, 'comida', debit, 6),
      e('Bebidas', 12000, 'comida', debit, 8),
      e('Comida viaje', 8538, 'comida', transfer, 3),
      e('Peajes', 6893.10, 'ocio', debit, 7),
      e('Compra dólares', 140000, 'tcredito', debit, 4),
      e('Ropa', 35000, 'fer', transfer, 8),
    ]);
  }

  @override
  Future<List<InstallmentPlan>> installmentPlans(DateTime month) {
    final tcDue = DateTime(month.year, month.month + 1, 2);
    final stDue = DateTime(month.year, month.month, 10);
    var n = 0;
    InstallmentPlan p(String title, String entity, double total, int cuotas, int pagas,
            int monthsAgo, int day) =>
        InstallmentPlan(
          id: 'plan-${n++}',
          title: title,
          entity: entity,
          purchaseDate: DateTime(month.year, month.month - monthsAgo, day),
          total: total,
          installments: cuotas,
          paidInstallments: pagas,
          nextDueDate: entity == 'Estancias' ? stDue : tcDue,
        );

    return _latency([
      p('Secador de pelo', 'TC Provincia', 72800, 6, 5, 5, 9),
      p('Camisa', 'TC Provincia', 54000, 4, 3, 3, 3),
      p('Conjunto', 'TC Provincia', 37000.02, 3, 2, 2, 4),
      p('Zapatillas', 'TC Provincia', 119000, 3, 2, 2, 8),
      p('Cilindros freno', 'TC Provincia', 99999, 3, 2, 2, 9),
      p('Vestido', 'TC Provincia', 190000, 3, 2, 2, 15),
      p('Remera', 'TC Provincia', 40900, 3, 1, 1, 30),
      p('Óptica', 'TC Provincia', 220000, 4, 1, 1, 11),
      p('Suéter', 'TC Provincia', 37500, 3, 1, 1, 11),
      p('Remeras + camisa', 'Estancias', 93350, 6, 1, 3, 16),
      p('Jean + remera', 'Estancias', 219430, 6, 1, 3, 20),
      p('Regalo', 'Estancias', 36000, 3, 0, 0, 11),
    ]);
  }

  static const _income = [1320000.0, 1359000.0, 1450000.0, 1500000.0, 1700099.08];
  static const _expenses = [1298000.0, 1312400.0, 1421700.0, 1467300.0, 1612800.0];

  @override
  Future<List<MonthSummary>> previousMonths(DateTime month) => _latency([
        for (var i = 0; i < _income.length; i++)
          MonthSummary(
            month: DateTime(month.year, month.month - (_income.length - i)),
            income: _income[i],
            expenses: _expenses[i],
          ),
      ]);
}