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
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.showInUah,
    required this.exchangeRate,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Перевіряємо, чи транзакція відхилена або зафейлена
    final isDeclined =
        transaction.apiStatus == TransactionApiStatus.fail ||
        transaction.tradeStatus == TransactionTradeStatus.declined;

    final isRefund = transaction.isRefund;

    // Якщо транзакція відхилена, колір суми та іконки завжди червоний
    final amountColor = isDeclined
        ? AppTheme.red
        : (isRefund ? AppTheme.green : AppTheme.red);

    final amountStr = CurrencyConverter.formatSigned(
      transaction.amount,
      showInUah: showInUah,
      rate: exchangeRate,
      paidAmount: transaction.conversionMode == UahConversionMode.paidAmount
          ? transaction.paidAmount
          : null,
    );
    final dateStr = DateFormat('MMM d, yyyy').format(transaction.dateTime);
    final timeStr = DateFormat('HH:mm').format(transaction.dateTime);

    // Визначаємо колір фону картки
    Color tileBgColor = AppTheme.cardColor;
    if (isSelected) {
      tileBgColor = AppTheme.gold.withValues(alpha: 0.1);
    } else if (isDeclined) {
      tileBgColor = AppTheme.red.withValues(
        alpha: 0.06,
      ); // Ніжний червоний фон для відхилених
    }

    // Визначаємо колір бордера
    Color tileBorderColor = AppTheme.cardBorderColor;
    if (isSelected) {
      tileBorderColor = AppTheme.gold;
    } else if (isDeclined) {
      tileBorderColor = AppTheme.red.withValues(alpha: 0.3); // Червоний контур
    }

    // Стиль тексту для назви мерчанта (якщо відхилено — робимо текст червонуватим)
    final merchantTextStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: isDeclined ? AppTheme.red.withValues(alpha: 0.9) : null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: tileBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tileBorderColor,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                    activeColor: AppTheme.gold,
                  ),
                  const SizedBox(width: 8),
                ],
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
                        style: merchantTextStyle,
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
                              color: isDeclined
                                  ? AppTheme.red.withValues(alpha: 0.08)
                                  : AppTheme.gold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isDeclined ? 'DECLINED' : transaction.category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDeclined
                                    ? AppTheme.red
                                    : AppTheme.gold,
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
                              color: isDeclined
                                  ? theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.6)
                                  : null,
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
                    Row(
                      children: [
                        Text(
                          amountStr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                            decoration: isDeclined
                                ? TextDecoration.lineThrough
                                : null, // Закреслюємо суму, якщо відхилено
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(transaction.apiStatus),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.side.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isDeclined
                            ? AppTheme.red.withValues(alpha: 0.7)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(TransactionApiStatus status) {
    return switch (status) {
      TransactionApiStatus.success => AppTheme.green,
      TransactionApiStatus.fail => AppTheme.red,
      TransactionApiStatus.pending => Colors.grey,
      TransactionApiStatus.init => Colors.grey,
    };
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('restaurant') ||
        lower.contains('fast food') ||
        lower.contains('bakeri')) {
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
    if (lower.contains('transport') ||
        lower.contains('taxi') ||
        lower.contains('ride')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('cloth') ||
        lower.contains('apparel') ||
        lower.contains('shoe')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('electron') ||
        lower.contains('computer') ||
        lower.contains('software')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('pharmacy') ||
        lower.contains('medical') ||
        lower.contains('doctor') ||
        lower.contains('hospital')) {
      return Icons.local_hospital_rounded;
    }
    if (lower.contains('cinema') ||
        lower.contains('movie') ||
        lower.contains('entertain') ||
        lower.contains('theater')) {
      return Icons.movie_rounded;
    }
    if (lower.contains('atm') || lower.contains('cash')) {
      return Icons.atm_rounded;
    }
    if (lower.contains('telecom') ||
        lower.contains('internet') ||
        lower.contains('cable')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('parking')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('education') ||
        lower.contains('school') ||
        lower.contains('college')) {
      return Icons.school_rounded;
    }
    if (lower.contains('utility') || lower.contains('utilities')) {
      return Icons.bolt_rounded;
    }
    return Icons.receipt_long_rounded;
  }
}
