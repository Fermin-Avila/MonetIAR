// lib/features/transactions/presentation/transaction_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetiar/core/utils/formatters.dart';
import 'package:monetiar/features/finance/domain/category.dart';
import 'package:monetiar/features/finance/domain/payment_method.dart';
import 'package:monetiar/features/finance/domain/transaction.dart';
import 'package:monetiar/features/finance/domain/wallet.dart';
import 'package:monetiar/features/transactions/application/transaction_actions.dart';

/// Acepta "1500", "1500,50", "1.500,50" y "1.500" (miles). Devuelve null si no es válido.
double? parseAmount(String raw) {
  var s = raw.trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  return double.tryParse(s);
}

Future<void> showTransactionForm(
  BuildContext context, {
  required List<Category> categories,
  required List<Wallet> wallets,
  Transaction? initial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _TransactionForm(categories: categories, wallets: wallets, initial: initial),
  );
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({required this.categories, required this.wallets, this.initial});
  final List<Category> categories;
  final List<Wallet> wallets;
  final Transaction? initial;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  static const _incomeCategoryName = 'Ingresos';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late TransactionType _type;
  late PaymentMethod _method;
  late DateTime _date;
  late bool _paid;
  String? _categoryId;
  String? _walletId;
  bool _walletTouched = false;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.initial == null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    final now = DateTime.now();
    _title = TextEditingController(text: t?.title ?? '');
    _amount = TextEditingController(text: t == null ? '' : _formatAmount(t.amount));
    _note = TextEditingController(text: t?.note ?? '');
    _type = t?.type ?? TransactionType.expense;
    _method = t?.paymentMethod ?? PaymentMethod.debit;
    _date = t?.date ?? DateTime(now.year, now.month, now.day);
    _paid = t?.isPaid ?? true;
    _categoryId = t?.categoryId;
    _walletId = t?.walletId ?? _defaultWalletId(_method);
    _walletTouched = t?.walletId != null;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _formatAmount(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceAll('.', ',');

  String? get _incomeCategoryId {
    for (final c in widget.categories) {
      if (c.name == _incomeCategoryName) return c.id;
    }
    return null;
  }

  List<Category> get _categoryOptions {
    final incomeId = _incomeCategoryId;
    if (_type == TransactionType.income) {
      final only = widget.categories.where((c) => c.id == incomeId).toList();
      return only.isEmpty ? widget.categories : only;
    }
    return widget.categories.where((c) => c.id != incomeId).toList();
  }

  String? _defaultWalletId(PaymentMethod m) {
    final wanted = switch (m) {
      PaymentMethod.cash => WalletType.cash,
      PaymentMethod.credit || PaymentMethod.additional => WalletType.creditCard,
      _ => WalletType.bank,
    };
    for (final w in widget.wallets) {
      if (w.type == wanted) return w.id;
    }
    return widget.wallets.isEmpty ? null : widget.wallets.first.id;
  }

  void _onTypeChanged(TransactionType v) {
    setState(() {
      _type = v;
      final incomeId = _incomeCategoryId;
      if (v == TransactionType.income) {
        _categoryId = incomeId ?? _categoryId;
      } else if (_categoryId == incomeId) {
        _categoryId = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    final tx = Transaction(
      id: widget.initial?.id ?? '',
      title: _title.text.trim(),
      amount: parseAmount(_amount.text)!,
      type: _type,
      categoryId: _categoryId,
      paymentMethod: _method,
      date: _date,
      isPaid: _paid,
      walletId: _walletId,
      note: note.isEmpty ? null : note,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(transactionActionsProvider).save(tx, isNew: _isNew);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'No se pudo guardar. Revisá tu conexión e intentá de nuevo.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: Text('"${_title.text}" se borrará y el saldo de la cuenta se ajustará.'),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(transactionActionsProvider).delete(widget.initial!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'No se pudo eliminar. Intentá de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = _categoryOptions;
    final categoryValue = options.any((c) => c.id == _categoryId) ? _categoryId : null;
    final walletValue = widget.wallets.any((w) => w.id == _walletId) ? _walletId : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_isNew ? 'Nuevo movimiento' : 'Editar movimiento',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<TransactionType>(
              groupValue: _type,
              onValueChanged: (v) {
                if (v != null) _onTypeChanged(v);
              },
              children: const {
                TransactionType.expense:
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Gasto')),
                TransactionType.income:
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Ingreso')),
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: _isNew,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                  labelText: 'Importe', prefixText: r'$ ', border: OutlineInputBorder()),
              validator: (v) {
                final a = parseAmount(v ?? '');
                return (a == null || a <= 0) ? 'Ingresá un importe mayor a 0' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Motivo', border: OutlineInputBorder(), counterText: ''),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresá un motivo' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('cat-$_type-$categoryValue'),
              initialValue: categoryValue,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Categoría', border: OutlineInputBorder()),
              items: [
                for (final c in options)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: Color(c.colorValue), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(c.name),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Elegí una categoría' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Medio de pago', border: OutlineInputBorder()),
              items: [
                for (final m in PaymentMethod.values)
                  DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _method = v;
                  if (!_walletTouched) _walletId = _defaultWalletId(v);
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('wallet-$walletValue'),
              initialValue: walletValue,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Cuenta', border: OutlineInputBorder()),
              items: [
                for (final w in widget.wallets)
                  DropdownMenuItem(value: w.id, child: Text(w.name)),
              ],
              onChanged: (v) => setState(() {
                _walletId = v;
                _walletTouched = true;
              }),
              validator: (v) => v == null ? 'Elegí una cuenta' : null,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Fecha'),
              trailing: Text(Fmt.dayHeader(_date),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: _pickDate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pagado'),
              subtitle: Text(_paid
                  ? 'El dinero ya se movió: ajusta el saldo de la cuenta.'
                  : 'Pendiente: no afecta el saldo hasta marcarlo pagado.'),
              value: _paid,
              onChanged: (v) => setState(() => _paid = v),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isNew ? 'Guardar' : 'Guardar cambios'),
            ),
            if (!_isNew)
              TextButton(
                onPressed: _busy ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: const Text('Eliminar movimiento'),
              ),
          ]),
        ),
      ),
    );
  }
}