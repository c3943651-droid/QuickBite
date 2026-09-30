import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  static String format(num value) => _format.format(value);

  static String compact(num value) {
    final amount = NumberFormat.currency(
      locale: 'es_MX',
      symbol: r'$',
      decimalDigits: value.truncateToDouble() == value ? 0 : 2,
    );
    return amount.format(value);
  }
}
