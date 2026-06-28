import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/transaction_provider.dart';
import 'package:bybit_card_tracker/presentation/screens/transaction_detail_screen.dart';
import 'package:bybit_card_tracker/presentation/widgets/transaction_tile.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedTxIds = {};

  bool get _isSelectionMode => _selectedTxIds.isNotEmpty;

  void _toggleSelection(String txnId) {
    setState(() {
      if (_selectedTxIds.contains(txnId)) {
        _selectedTxIds.remove(txnId);
      } else {
        _selectedTxIds.add(txnId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTxIds.clear();
    });
  }

  Future<void> _changeCategoryForSelected() async {
    final settings = ref.read(settingsProvider);
    String? selectedCategory;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Change Category'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                hint: const Text('Select category'),
                items: settings.allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setStateDialog(() => selectedCategory = val);
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCategory != null) Navigator.pop(ctx, selectedCategory);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          }
        );
      }
    );

    if (result != null) {
      final ids = _selectedTxIds.toList();
      _clearSelection();
      for (final id in ids) {
        await ref.read(transactionProvider.notifier).setTransactionCategory(id, result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category updated for ${ids.length} transactions.')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _changeConversionModeForSelected() async {
    UahConversionMode? selectedMode;
    final result = await showDialog<UahConversionMode>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Change Conversion Mode'),
              content: DropdownButtonFormField<UahConversionMode>(
                initialValue: selectedMode,
                hint: const Text('Select conversion mode'),
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
                onChanged: (val) {
                  if (val != null) setStateDialog(() => selectedMode = val);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMode != null) Navigator.pop(ctx, selectedMode);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final ids = _selectedTxIds.toList();
      _clearSelection();
      await ref
          .read(transactionProvider.notifier)
          .setConversionModeForMany(ids, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Conversion mode updated for ${ids.length} transaction${ids.length == 1 ? '' : 's'}.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txnState = ref.watch(cardTransactionsAsyncProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedTxIds.length} selected') 
            : const Text('Transaction History'),
        leading: _isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.currency_exchange_rounded),
                  tooltip: 'Change Conversion Mode',
                  onPressed: _changeConversionModeForSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.category_rounded),
                  tooltip: 'Change Category',
                  onPressed: _changeCategoryForSelected,
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search merchant or category...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: txnState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (transactions) {
          final filtered = transactions.where((tx) {
            final name = tx.merchantName.toLowerCase();
            final category = tx.category.toLowerCase();
            return name.contains(_searchQuery) || category.contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No transactions found', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final tx = filtered[index];
              return TransactionTile(
                transaction: tx,
                showInUah: settings.showInUah,
                exchangeRate: settings.exchangeRate,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTxIds.contains(tx.id),
                onLongPress: () {
                  if (!_isSelectionMode) _toggleSelection(tx.id);
                },
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(tx.id);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(
                          transaction: tx,
                          showInUah: settings.showInUah,
                          exchangeRate: settings.exchangeRate,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
