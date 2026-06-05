import 'package:flutter/material.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';

/// Segmented button for switching between USD and UAH display.
class CurrencyToggle extends StatelessWidget {
  final bool showInUah;
  final ValueChanged<bool> onChanged;

  const CurrencyToggle({
    super.key,
    required this.showInUah,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TogglePill(
            label: '\$ USD',
            isActive: !showInUah,
            onTap: () => onChanged(false),
          ),
          _TogglePill(
            label: '₴ UAH',
            isActive: showInUah,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.gold.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.gold : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
