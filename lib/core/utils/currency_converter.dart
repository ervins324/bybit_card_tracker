import 'package:intl/intl.dart';

/// Helper for USD ↔ UAH conversion and currency formatting.
class CurrencyConverter {
  CurrencyConverter._();

  static double toUah(double usd, double rate) => usd * rate;
  static double toUsd(double uah, double rate) => uah / rate;

  /// Formats [amount] with the appropriate currency symbol.
  /// [showInUah] controls whether to display in UAH or USD.
  /// If [showInUah], the [amount] is multiplied by [rate] first.
  static String format(
    double amount, {
    required bool showInUah,
    required double rate,
  }) {
    final value = showInUah ? toUah(amount, rate) : amount;
    final symbol = showInUah ? '₴' : '\$';
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  /// Formats with sign indicator (+ for refunds, − for purchases).
  static String formatSigned(
    double amount, {
    required bool showInUah,
    required double rate,
  }) {
    final value = showInUah ? toUah(amount, rate) : amount;
    final symbol = showInUah ? '₴' : '\$';
    final prefix = value >= 0 ? '+' : '';
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return '$prefix${formatter.format(value)}';
  }
}
