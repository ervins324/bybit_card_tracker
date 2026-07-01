import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
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
  
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;

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

  Future<void> _showFilterBottomSheet() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 20),
                  
                  // Transaction Type Filter
                  Text('Transaction Type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedType,
                    dropdownColor: AppTheme.cardColor,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Purchases', child: Text('Purchases')),
                      DropdownMenuItem(value: 'Refunds', child: Text('Refunds')),
                    ],
                    onChanged: (val) => setSheetState(() => _selectedType = val ?? 'All'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Filter
                  Text('Status', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: AppTheme.cardColor,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'Declined/Failed', child: Text('Declined/Failed')),
                    ],
                    onChanged: (val) => setSheetState(() => _selectedStatus = val ?? 'All'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Range Filter
                  Text('Date Range', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.cardBorderColor),
                    ),
                    title: Text(_selectedDateRange == null 
                        ? 'Select date range' 
                        : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'),
                    trailing: _selectedDateRange == null 
                        ? const Icon(Icons.date_range)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setSheetState(() => _selectedDateRange = null),
                          ),
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _selectedDateRange,
                      );
                      if (range != null) {
                        setSheetState(() => _selectedDateRange = DateTimeRange(
                          start: range.start,
                          end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
                        ));
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Apply filters to main screen
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
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
            : [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  color: (_selectedType != 'All' || _selectedStatus != 'All' || _selectedDateRange != null) ? AppTheme.gold : null,
                  tooltip: 'Filter',
                  onPressed: _showFilterBottomSheet,
                )
              ],
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
            // Search Query
            final name = tx.merchantName.toLowerCase();
            final category = tx.category.toLowerCase();
            if (_searchQuery.isNotEmpty && !name.contains(_searchQuery) && !category.contains(_searchQuery)) {
              return false;
            }
            
            // Type Filter
            if (_selectedType == 'Purchases' && !tx.isPurchase) return false;
            if (_selectedType == 'Refunds' && !tx.isRefund) return false;
            
            // Status Filter
            if (_selectedStatus != 'All') {
               final isDeclined = tx.apiStatus == TransactionApiStatus.fail || tx.tradeStatus == TransactionTradeStatus.declined;
               final isPending = tx.apiStatus == TransactionApiStatus.pending || tx.tradeStatus == TransactionTradeStatus.inProgress;
               if (_selectedStatus == 'Completed' && (isDeclined || isPending)) return false;
               if (_selectedStatus == 'Pending' && !isPending) return false;
               if (_selectedStatus == 'Declined/Failed' && !isDeclined) return false;
            }
            
            // Date Range Filter
            if (_selectedDateRange != null) {
              if (tx.dateTime.isBefore(_selectedDateRange!.start) || tx.dateTime.isAfter(_selectedDateRange!.end)) {
                return false;
              }
            }
            
            return true;
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
