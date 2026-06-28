import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bybit_card_tracker/core/constants/merchant_categories.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/core/utils/currency_converter.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionEntity transaction;
  final bool showInUah;
  final double exchangeRate;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.showInUah,
    required this.exchangeRate,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  String? _selectedCategory;

  // Використовуємо локальну змінну ТІЛЬКИ для збереження ручного вибору користувача в UI
  UahConversionMode? _userSelectedConversionMode;
  bool _saving = false;
  bool _savingMode = false;

  String _resolvedCategory(TransactionEntity tx, List<String> allCategories) {
    if (tx.hasCustomCategory) {
      final custom = tx.customCategory!;
      if (allCategories.contains(custom)) return custom;
    }

    final userRules = ref.read(settingsProvider).categoryRules;

    final resolved = MerchantCategories.resolve(
      tx.merchantName,
      mccCode: tx.mccCode,
      apiCategory: tx.category,
      userRules: userRules,
    );

    return allCategories.contains(resolved)
        ? resolved
        : MerchantCategories.fallbackCategory;
  }

  @override
  Widget build(BuildContext context) {
    final modelAsync = ref.watch(
      transactionModelProvider(widget.transaction.id),
    );
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final tx = widget.transaction;

    // Визначаємо актуальний режим на льоту: або вибір користувача, або значення з об'єкта
    final currentConversionMode =
        _userSelectedConversionMode ?? tx.conversionMode;

    final amountColor = tx.isRefund ? AppTheme.green : AppTheme.red;
    final amountStr = CurrencyConverter.formatSigned(
      tx.amount,
      showInUah: widget.showInUah,
      rate: widget.exchangeRate,
      paidAmount: currentConversionMode == UahConversionMode.paidAmount
          ? tx.paidAmount
          : null,
    );

    _selectedCategory ??= _resolvedCategory(tx, settings.allCategories);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: modelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (model) {
          final apiFields =
              model?.apiFieldsForDisplay ??
              tx.rawApiData.map((k, v) => MapEntry(k, v?.toString() ?? ''));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeaderCard(
                merchantName: tx.merchantName,
                amount: amountStr,
                amountColor: amountColor,
                date: DateFormat('MMM d, yyyy · HH:mm').format(tx.dateTime),
                sideLabel: tx.side.label,
                apiStatusLabel: tx.apiStatus.label,
                tradeStatusLabel: tx.tradeStatus.label,
              ),
              const SizedBox(height: 16),

              // ── Category ──────────────────────────────────────────
              Text('Category', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  helperText: tx.hasCustomCategory
                      ? 'Custom category for this transaction only'
                      : 'Auto-assigned',
                ),
                items: settings.allCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _saveCategory(reset: false),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save category'),
                    ),
                  ),
                  if (tx.hasCustomCategory) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => _saveCategory(reset: true),
                      child: const Text('Reset'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── UAH Conversion Mode ───────────────────────────────
              Text('UAH Conversion', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<UahConversionMode>(
                initialValue: currentConversionMode,
                decoration: const InputDecoration(
                  helperText: 'How to convert USD amount to UAH',
                ),
                items: const [
                  DropdownMenuItem(
                    value: UahConversionMode.rate,
                    child: Text('Use exchange rate'),
                  ),
                  DropdownMenuItem(
                    value: UahConversionMode.paidAmount,
                    child: Text('Use paidAmount from API'),
                  ),
                ],
                onChanged: _savingMode
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _userSelectedConversionMode = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _savingMode ? null : _saveConversionMode,
                child: _savingMode
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save conversion mode'),
              ),
              const SizedBox(height: 24),

              // ── API response ──────────────────────────────────────
              Text('API response', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (apiFields.isEmpty)
                Text(
                  'No raw API data stored. Sync again to capture full details.',
                  style: theme.textTheme.bodySmall,
                )
              else
                ...apiFields.entries.map(
                  (entry) => _ApiFieldRow(
                    label: _labelForApiKey(entry.key),
                    value: _formatApiValue(entry.key, entry.value),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveCategory({required bool reset}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(transactionProvider.notifier)
          .setTransactionCategory(
            widget.transaction.id,
            reset ? null : _selectedCategory,
          );
      ref.invalidate(transactionModelProvider(widget.transaction.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reset ? 'Category reset to auto-assignment.' : 'Category saved.',
            ),
          ),
        );
        if (reset) {
          final settings = ref.read(settingsProvider);
          setState(() {
            _selectedCategory = _resolvedCategory(
              widget.transaction,
              settings.allCategories,
            );
          });
        }
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveConversionMode() async {
    final modeToSave =
        _userSelectedConversionMode ?? widget.transaction.conversionMode;

    setState(() => _savingMode = true);
    try {
      await ref
          .read(transactionProvider.notifier)
          .setConversionMode(widget.transaction.id, modeToSave);
      ref.invalidate(transactionModelProvider(widget.transaction.id));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Conversion mode saved.')));

        setState(() {
          _userSelectedConversionMode = null;
        });

        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _savingMode = false);
    }
  }

  static String _labelForApiKey(String key) {
    return switch (key) {
      'txnId' => 'Transaction ID',
      'orderNo' => 'Order ID',
      'bizId' => 'Business ID',
      'bizTxnId' => 'Business Txn ID',
      'merchName' => 'Merchant',
      'merchCategoryDesc' => 'Merchant category (API)',
      'mccCode' => 'MCC code',
      'merchCity' => 'City',
      'merchCountry' => 'Country',
      'basicCurrency' => 'Currency',
      'basicAmount' => 'Amount',
      'transactionAmount' => 'Transaction amount',
      'transactionCurrency' => 'Transaction currency',
      'paidAmount' => 'Paid amount',
      'paidCurrency' => 'Paid currency',
      'billAmount' => 'Bill amount',
      'totalFees' => 'Total fees',
      'totalTax' => 'Total tax',
      'foreignTransactionFee' => 'Foreign transaction fee',
      'withdrawalFee' => 'Withdrawal fee',
      'bonusAmount' => 'Bonus amount',
      'txnCreate' => 'Created',
      'pan4' => 'Card (last 4)',
      'pan6' => 'Card (first 6)',
      'side' => 'Transaction type',
      'tradeStatus' => 'Trade status',
      'status' => 'Status',
      'declinedReason' => 'Declined reason',
      'uid' => 'User ID',
      _ => key,
    };
  }

  static String _formatApiValue(String key, String value) {
    final lower = key.toLowerCase();
    if (lower.contains('time') ||
        lower.contains('date') ||
        lower == 'txncreate') {
      final ms = int.tryParse(value);
      if (ms != null) {
        return DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(DateTime.fromMillisecondsSinceEpoch(ms));
      }
    }
    if (key == 'side') {
      return switch (value) {
        '1' => 'Authorization',
        '2' => 'Authorization Reversal',
        '3' => 'Purchase',
        '4' => 'Refund (unDeduct)',
        '5' => 'Refund',
        '6' => 'Chargeback',
        '7' => 'Direct Purchase',
        '8' => 'Refund Reversal',
        '13' => 'ATM Withdrawal',
        _ => value,
      };
    }
    if (key == 'tradeStatus') {
      return switch (value) {
        '0' => 'In Progress',
        '1' => 'Completed',
        '2' => 'Declined',
        '3' => 'Reversal',
        _ => value,
      };
    }
    if (key == 'status') {
      return switch (value) {
        '-1' => 'Init',
        '0' => 'Pending',
        '1' => 'Success',
        '2' => 'Fail',
        _ => value,
      };
    }
    return value;
  }
}

class _HeaderCard extends StatelessWidget {
  final String merchantName;
  final String amount;
  final Color amountColor;
  final String date;
  final String sideLabel;
  final String apiStatusLabel;
  final String tradeStatusLabel;

  const _HeaderCard({
    required this.merchantName,
    required this.amount,
    required this.amountColor,
    required this.date,
    required this.sideLabel,
    required this.apiStatusLabel,
    required this.tradeStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            merchantName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(date, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            '$sideLabel · API: $apiStatusLabel · Trade: $tradeStatusLabel',
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.gold),
          ),
        ],
      ),
    );
  }
}

class _ApiFieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _ApiFieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
