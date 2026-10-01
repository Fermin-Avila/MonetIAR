// lib/features/finance/presentation/month_selector.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/core/utils/formatters.dart';
import 'package:monetiar/features/finance/application/finance_providers.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(CupertinoIcons.chevron_left, size: 18),
        onPressed: () => notifier.select(DateTime(month.year, month.month - 1)),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 96),
        child: Text(
          Fmt.monthYear(month),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(CupertinoIcons.chevron_right, size: 18),
        onPressed: () => notifier.select(DateTime(month.year, month.month + 1)),
      ),
    ]);
  }
}