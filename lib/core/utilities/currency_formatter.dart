import 'package:intl/intl.dart';

/// Currency Formatter for Rupiah
class CurrencyFormatter {
  CurrencyFormatter._();

  static const int defaultDecimalDigits = 0;

  static String format(num data, {int? decimalDigits}) {
    return NumberFormat.simpleCurrency(
      locale: 'id',
      decimalDigits: decimalDigits ?? defaultDecimalDigits,
    ).format(data);
  }

  static String compact(num data, {int? decimalDigits, bool withSymbol = true}) {
    return NumberFormat.compactSimpleCurrency(
      locale: 'id',
      name: withSymbol ? null : '',
      decimalDigits: decimalDigits ?? defaultDecimalDigits,
    ).format(data);
  }

  static String withoutSymbol(num data, {int? decimalDigits}) {
    return NumberFormat.currency(
      locale: 'id',
      decimalDigits: decimalDigits ?? defaultDecimalDigits,
      symbol: "",
    ).format(data);
  }

  static String currencySymbol() {
    return NumberFormat.simpleCurrency(
      locale: 'id',
    ).currencySymbol;
  }
}
