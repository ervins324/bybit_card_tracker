import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/transaction_provider.dart';

// ── Derived statistics providers (card purchases only) ─────────────────────

/// Total spending (purchases only, as a positive number).
final totalSpendUsdProvider = Provider<double>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  final settings = ref.watch(settingsProvider);

  return txns.where((tx) => tx.isPurchase).fold<double>(0.0, (sum, tx) {
    final absValue = tx
        .effectiveDisplayAmount(
          showInUah: settings.showInUah,
          rate: settings.exchangeRate,
        )
        .abs();
    return sum + absValue;
  });
});

/// Total refunds.
final totalRefundsUsdProvider = Provider<double>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  final settings = ref.watch(settingsProvider);
  return txns
      .where((tx) => tx.isRefund)
      .fold<double>(
        0.0,
        (sum, tx) =>
            sum +
            tx
                .effectiveDisplayAmount(
                  showInUah: settings.showInUah,
                  rate: settings.exchangeRate,
                )
                .abs(), // <--- Додано .abs()
      );
});

/// Net spending (purchases - refunds).
final netSpendUsdProvider = Provider<double>((ref) {
  return ref.watch(totalSpendUsdProvider) - ref.watch(totalRefundsUsdProvider);
});

/// Category breakdown using per-transaction conversion.
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  final settings = ref.watch(settingsProvider);
  final map = <String, double>{};
  for (final tx in txns) {
    if (!tx.isPurchase) continue;
    final value = tx
        .effectiveDisplayAmount(
          showInUah: settings.showInUah,
          rate: settings.exchangeRate,
        )
        .abs(); // <--- Додано .abs()
    map[tx.category] = (map[tx.category] ?? 0) + value;
  }
  return Map.fromEntries(
    map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
});

/// Monthly spending breakdown using per-transaction conversion.
final monthlySpendProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(cardTransactionsProvider);
  final settings = ref.watch(settingsProvider);
  final map = <String, double>{};
  final formatter = DateFormat('yyyy-MM');
  for (final tx in txns) {
    if (!tx.isPurchase) continue;
    final key = formatter.format(tx.dateTime);
    final value = tx
        .effectiveDisplayAmount(
          showInUah: settings.showInUah,
          rate: settings.exchangeRate,
        )
        .abs(); // <--- Додано .abs()
    map[key] = (map[key] ?? 0) + value;
  }
  return Map.fromEntries(
    map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
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
  final symbol = settings.showInUah ? '₴' : '\$';
  return '$symbol${total.toStringAsFixed(2)}';
});
