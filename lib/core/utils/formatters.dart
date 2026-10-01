// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

abstract final class Fmt {
  static final _money =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 0);
  static final _compact = NumberFormat.compactCurrency(
      locale: 'es_AR', symbol: r'$', decimalDigits: 1);

  static String money(num v) => _money.format(v);
  static String compact(num v) => _compact.format(v);

  static String monthYear(DateTime d) => _cap(DateFormat.yMMMM('es_AR').format(d));
  static String monthShort(DateTime d) =>
      _cap(DateFormat.MMM('es_AR').format(d).replaceAll('.', ''));
  static String dayMonth(DateTime d) =>
      DateFormat('d MMM', 'es_AR').format(d).replaceAll('.', '');

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String dayHeader(DateTime d) =>
      _cap(DateFormat('EEE d MMM', 'es_AR').format(d).replaceAll('.', ''));
}