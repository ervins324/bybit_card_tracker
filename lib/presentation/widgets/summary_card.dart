import 'package:flutter/material.dart';

import 'package:bybit_card_tracker/core/theme/app_theme.dart';

/// Glassmorphic-styled summary card showing total spend.
/// Receives pre-computed display values (already in the correct currency).
class SummaryCard extends StatelessWidget {
  /// Total spend already converted to the display currency.
  final double totalSpendUsd;

  /// Total refunds already converted to the display currency.
  final double totalRefundsUsd;

  final int transactionCount;
  final bool showInUah;
  final double exchangeRate;

  const SummaryCard({
    super.key,
    required this.totalSpendUsd,
    required this.totalRefundsUsd,
    required this.transactionCount,
    required this.showInUah,
    required this.exchangeRate,
  });

  String _format(double value) {
    final symbol = showInUah ? '₴' : '\$';
    return '$symbol${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netSpend = totalSpendUsd - totalRefundsUsd;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold.withValues(alpha: 0.15), AppTheme.cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Net Spending',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _format(netSpend),
                key: ValueKey(_format(netSpend)),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Purchases',
                  value: _format(totalSpendUsd),
                  color: AppTheme.red,
                ),
                const SizedBox(width: 24),
                _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Refunds',
                  value: _format(totalRefundsUsd),
                  color: AppTheme.green,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$transactionCount txns',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
