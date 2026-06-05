import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/core/utils/currency_converter.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';

/// A single transaction list item with merchant info, category chip,
/// date/time, and color-coded signed amount.
class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final bool showInUah;
  final double exchangeRate;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.showInUah,
    required this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRefund = transaction.isRefund;
    final amountColor = isRefund ? AppTheme.green : AppTheme.red;
    final amountStr = CurrencyConverter.formatSigned(
      transaction.amount,
      showInUah: showInUah,
      rate: exchangeRate,
    );
    final dateStr = DateFormat('MMM d, yyyy').format(transaction.dateTime);
    final timeStr = DateFormat('HH:mm').format(transaction.dateTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ─ Category icon ─
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(transaction.category),
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // ─ Merchant & category ─
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchantName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$dateStr  $timeStr',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─ Amount ─
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.side.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('restaurant') || lower.contains('fast food') || lower.contains('bakeri')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('grocery') || lower.contains('food')) {
      return Icons.shopping_cart_rounded;
    }
    if (lower.contains('gas') || lower.contains('fuel')) {
      return Icons.local_gas_station_rounded;
    }
    if (lower.contains('hotel') || lower.contains('lodging')) {
      return Icons.hotel_rounded;
    }
    if (lower.contains('airline') || lower.contains('travel')) {
      return Icons.flight_rounded;
    }
    if (lower.contains('transport') || lower.contains('taxi') || lower.contains('ride')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('cloth') || lower.contains('apparel') || lower.contains('shoe')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('electron') || lower.contains('computer') || lower.contains('software')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('pharmacy') || lower.contains('medical') || lower.contains('doctor') || lower.contains('hospital')) {
      return Icons.local_hospital_rounded;
    }
    if (lower.contains('cinema') || lower.contains('movie') || lower.contains('entertain') || lower.contains('theater')) {
      return Icons.movie_rounded;
    }
    if (lower.contains('atm') || lower.contains('cash')) {
      return Icons.atm_rounded;
    }
    if (lower.contains('telecom') || lower.contains('internet') || lower.contains('cable')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('parking')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('education') || lower.contains('school') || lower.contains('college')) {
      return Icons.school_rounded;
    }
    if (lower.contains('utility') || lower.contains('utilities')) {
      return Icons.bolt_rounded;
    }
    return Icons.receipt_long_rounded;
  }
}
