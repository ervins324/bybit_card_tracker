import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/transaction_provider.dart';

// ── Derived statistics providers (card purchases only) ─────────────────────

/// Total spending (purchases only, as a positive number) in USD.
final totalSpendUsdProvider = Provider<double>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  return txns
      .where((tx) => tx.isPurchase)
      .fold<double>(0.0, (sum, tx) => sum + tx.absoluteAmount);
});

/// Total refunds in USD.
final totalRefundsUsdProvider = Provider<double>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  return txns
      .where((tx) => tx.isRefund)
      .fold<double>(0.0, (sum, tx) => sum + tx.absoluteAmount);
});

/// Net spending (purchases - refunds) in USD.
final netSpendUsdProvider = Provider<double>((ref) {
  return ref.watch(totalSpendUsdProvider) -
      ref.watch(totalRefundsUsdProvider);
});

/// Category breakdown: `{ "Restaurants": 150.0, "Grocery Stores": 80.0, … }`
/// Values are in USD (absolute amounts of purchases).
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  final map = <String, double>{};

  for (final tx in txns) {
    if (!tx.isPurchase) continue;
    map[tx.category] = (map[tx.category] ?? 0) + tx.absoluteAmount;
  }

  final sorted = Map.fromEntries(
    map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
  return sorted;
});

/// Monthly spending breakdown: `{ "2024-01": 500.0, "2024-02": 320.0, … }`
final monthlySpendProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  final map = <String, double>{};
  final formatter = DateFormat('yyyy-MM');

  for (final tx in txns) {
    if (!tx.isPurchase) continue;
    final key = formatter.format(tx.dateTime);
    map[key] = (map[key] ?? 0) + tx.absoluteAmount;
  }

  final sorted = Map.fromEntries(
    map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return sorted;
});

/// Total card transaction count.
final transactionCountProvider = Provider<int>((ref) {
  return ref.watch(cardTransactionsProvider).length;
});

/// Total points earned from bonus activity.
final totalPointsEarnedProvider = Provider<int>((ref) {
  return ref
      .watch(bonusTransactionsProvider)
      .where((tx) => tx.signedPointAmount > 0)
      .fold<int>(0, (sum, tx) => sum + tx.signedPointAmount);
});

/// Total points spent from bonus activity.
final totalPointsSpentProvider = Provider<int>((ref) {
  return ref
      .watch(bonusTransactionsProvider)
      .where((tx) => tx.signedPointAmount < 0)
      .fold<int>(0, (sum, tx) => sum + tx.signedPointAmount.abs());
});

/// Formatted total spend string respecting the current currency setting.
final formattedTotalSpendProvider = Provider<String>((ref) {
  final total = ref.watch(totalSpendUsdProvider);
  final settings = ref.watch(settingsProvider);
  final value =
      settings.showInUah ? total * settings.exchangeRate : total;
  final symbol = settings.showInUah ? '₴' : '\$';
  return '$symbol${value.toStringAsFixed(2)}';
});
