// lib/features/transactions/presentation/transaction_tile.dart
import 'package:flutter/material.dart';
import 'package:monetiar/core/theme/app_theme.dart';
import 'package:monetiar/core/utils/formatters.dart';
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/presentation/category_icons.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    required this.category,
    this.walletName,
    this.onTap,
  });

  final Transaction tx;
  final Category category;
  final String? walletName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final isIncome = !tx.isExpense;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final details = [
      category.name,
      tx.paymentMethod.label,
      ?walletName,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(categoryIcon(category.iconKey), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isIncome ? '+' : '−'} ${Fmt.money(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isIncome ? AppTheme.income : null,
              ),
            ),
            if (!tx.isPaid)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Pendiente',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700)),
              ),
          ]),
        ]),
      ),
    );
  }
}