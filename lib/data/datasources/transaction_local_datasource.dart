import 'package:hive/hive.dart';

import 'package:bybit_card_tracker/data/models/transaction_model.dart';

/// Local data source backed by a Hive box.
///
/// Transactions are stored as raw Maps keyed by `txnId` to avoid duplicates.
class TransactionLocalDatasource {
  static const String _boxName = 'transactions';

  /// Opens (or returns the already-opened) Hive box.
  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map>(_boxName);
    }
    return Hive.openBox<Map>(_boxName);
  }

  /// Saves a list of transactions, using `txnId` as the unique key
  /// to prevent duplicates on re-sync.
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    final box = await _openBox();
    final entries = <String, Map>{};
    for (final tx in transactions) {
      entries[tx.txnId] = tx.toMap();
    }
    await box.putAll(entries);
  }

  /// Returns all cached transactions sorted by date (newest first).
  Future<List<TransactionModel>> getCachedTransactions() async {
    final box = await _openBox();
    final models = box.values
        .map((map) => TransactionModel.fromMap(map))
        .toList();

    // Sort newest → oldest
    models.sort((a, b) {
      final aTime = a.txnCreate ?? 0;
      final bTime = b.txnCreate ?? 0;
      return bTime.compareTo(aTime);
    });

    return models;
  }

  /// Removes all cached transactions.
  Future<void> clearCache() async {
    final box = await _openBox();
    await box.clear();
  }
}
