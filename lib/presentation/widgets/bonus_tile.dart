import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bybit_card_tracker/core/constants/bonus_types.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';

/// A list item for reward point bonus activity (earn / spend).
class BonusTile extends StatelessWidget {
  final TransactionEntity transaction;

  const BonusTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEarned = transaction.signedPointAmount > 0;
    final color = isEarned ? AppTheme.green : AppTheme.red;
    final points = transaction.signedPointAmount.abs();
    final dateStr = DateFormat('MMM d, yyyy').format(transaction.dateTime);
    final timeStr = DateFormat('HH:mm').format(transaction.dateTime);
    final sideLabel = BonusTypes.sideLabel(transaction.rewardSide);

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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
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
                          sideLabel,
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
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${isEarned ? '+' : '-'}$points pts',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
