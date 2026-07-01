import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bybit_card_tracker/core/constants/api_constants.dart';
import 'package:bybit_card_tracker/core/error/failures.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/core/utils/network_error_messages.dart';
import 'package:bybit_card_tracker/presentation/screens/category_rules_screen.dart';
import 'package:bybit_card_tracker/presentation/providers/credentials_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/statistics_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/transaction_provider.dart';
import 'package:bybit_card_tracker/presentation/widgets/category_pie_chart.dart';
import 'package:bybit_card_tracker/presentation/widgets/currency_toggle.dart';
import 'package:bybit_card_tracker/presentation/widgets/daily_bar_chart.dart';
import 'package:bybit_card_tracker/presentation/widgets/period_picker.dart';
import 'package:bybit_card_tracker/presentation/widgets/summary_card.dart';

/// Dashboard screen with summary card, pie chart, and bar chart.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final txnState = ref.watch(transactionProvider);
    final settings = ref.watch(settingsProvider);
    final totalSpend = ref.watch(totalSpendUsdProvider);
    final totalRefunds = ref.watch(totalRefundsUsdProvider);
    final txnCount = ref.watch(transactionCountProvider);
    final categoryData = ref.watch(categoryBreakdownProvider);
    final dailyData = ref.watch(dailySpendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          CurrencyToggle(
            showInUah: settings.showInUah,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggleCurrency(),
          ),
          const SizedBox(width: 8),
          // Sync button
          IconButton(
            icon: txnState.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.gold,
                    ),
                  )
                : Icon(Icons.sync_rounded, color: AppTheme.gold),
            tooltip: 'Sync transactions',
            onPressed: txnState.isLoading
                ? null
                : () => ref.read(transactionProvider.notifier).sync(),
          ),
          // Card Selector
          Builder(builder: (context) {
            final allTxns = txnState.valueOrNull ?? [];
            final cards = allTxns
                .map((t) => t.pan4)
                .where((pan) => pan.isNotEmpty && pan != '****')
                .toSet()
                .toList()
              ..sort();
              
            final selectedCard = ref.watch(selectedCardProvider);

            return PopupMenuButton<String?>(
              icon: Icon(
                Icons.credit_card_rounded,
                color: selectedCard == null ? null : AppTheme.gold,
              ),
              tooltip: 'Select Card',
              color: AppTheme.cardColor,
              onSelected: (value) {
                ref.read(selectedCardProvider.notifier).state = value;
              },
              itemBuilder: (_) {
                final items = <PopupMenuEntry<String?>>[
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Cards'),
                  ),
                ];
                if (cards.isNotEmpty) {
                  items.add(const PopupMenuDivider());
                  items.addAll(cards.map((pan) => PopupMenuItem(
                    value: pan,
                    child: Text('Card **** $pan'),
                  )));
                }
                return items;
              },
            );
          }),
          // Settings
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.cardColor,
            onSelected: (value) => _handleMenu(context, ref, value),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'endpoint',
                child: ListTile(
                  leading: Icon(Icons.dns_rounded),
                  title: Text('API Endpoint'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'categories',
                child: ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Categories'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'rate',
                child: ListTile(
                  leading: Icon(Icons.currency_exchange_rounded),
                  title: Text('Exchange Rate'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Clear Cache'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Disconnect'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: txnState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error,
          onRetry: () => ref.read(transactionProvider.notifier).sync(),
        ),
        data: (_) => RefreshIndicator(
          color: AppTheme.gold,
          onRefresh: () => ref.read(transactionProvider.notifier).sync(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 8),
              // Period Picker
              const PeriodPicker(),
              const SizedBox(height: 8),
              // Summary card
              SummaryCard(
                totalSpendUsd: totalSpend,
                totalRefundsUsd: totalRefunds,
                transactionCount: txnCount,
                showInUah: settings.showInUah,
                exchangeRate: settings.exchangeRate,
              ),
              const SizedBox(height: 8),
              // Pie chart
              CategoryPieChart(
                data: categoryData,
                showInUah: settings.showInUah,
                exchangeRate: settings.exchangeRate,
              ),
              // Daily Bar chart
              DailyBarChart(
                data: dailyData,
                showInUah: settings.showInUah,
                exchangeRate: settings.exchangeRate,
              ),
              const SizedBox(height: 24),

              // Empty state hint
              if (txnCount == 0)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet.\nTap the sync button to fetch your data.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenu(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'endpoint':
        _showEndpointDialog(context, ref);
      case 'categories':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CategoryRulesScreen()),
        );
      case 'rate':
        _showExchangeRateDialog(context, ref);
      case 'clear':
        ref.read(transactionProvider.notifier).clearData();
      case 'logout':
        ref.read(credentialsProvider.notifier).clear();
        ref.read(transactionProvider.notifier).clearData();
        Navigator.of(context).pushReplacementNamed('/setup');
    }
  }

  void _showExchangeRateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).exchangeRate.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('UAH Exchange Rate'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '1 USD = ? UAH',
            hintText: '41.0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate > 0) {
                ref.read(settingsProvider.notifier).setExchangeRate(rate);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEndpointDialog(BuildContext context, WidgetRef ref) {
    final credentials = ref.read(credentialsProvider).valueOrNull;
    var selected = credentials?.baseUrl ?? ApiConstants.mainnetBaseUrl;
    final endpoints = Map<String, String>.from(ApiConstants.regionalEndpoints);
    if (!endpoints.containsValue(selected)) {
      endpoints['Current'] = selected;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('API Endpoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If sync fails on mobile, try a regional server or the bytick mirror.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Server'),
                dropdownColor: AppTheme.cardColor,
                items: endpoints.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.key, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => selected = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(credentialsProvider.notifier)
                    .updateBaseUrl(selected);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Endpoint updated. Tap sync.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = switch (error) {
      Failure(:final message) => message,
      _ => NetworkErrorMessages.format(error),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: AppTheme.red),
            const SizedBox(height: 16),
            Text(
              'Connection problem',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
