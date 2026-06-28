import 'package:hive/hive.dart';
import 'package:bybit_card_tracker/data/models/transaction_model.dart';

/// Local data source backed by a Hive box.
///
/// Transactions are stored as raw Maps keyed by `txnId` to avoid duplicates.
class TransactionLocalDatasource {
  static const String _boxName = 'transactions';

  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map>(_boxName);
    }
    return Hive.openBox<Map>(_boxName);
  }

  /// Saves transactions, preserving user overrides such as [customCategory] and [conversionMode].
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    final box = await _openBox();
    for (final tx in transactions) {
      final existing = box.get(tx.txnId);
      final map = tx.toMap();
      if (existing != null) {
        if (existing['customCategory'] != null) {
          map['customCategory'] = existing['customCategory'];
        }
        if (existing['conversionMode'] != null) {
          map['conversionMode'] = existing['conversionMode'];
        }
      }
      await box.put(tx.txnId, map);
    }
  }

  Future<List<TransactionModel>> getCachedTransactions() async {
    final box = await _openBox();
    final models = box.values
        .map((map) => TransactionModel.fromMap(map))
        .toList();
    models.sort((a, b) {
      final aTime = a.txnCreate ?? 0;
      final bTime = b.txnCreate ?? 0;
      return bTime.compareTo(aTime);
    });
    return models;
  }

  Future<TransactionModel?> getById(String txnId) async {
    final box = await _openBox();
    final map = box.get(txnId);
    if (map == null) return null;
    return TransactionModel.fromMap(map);
  }

  Future<void> updateCategory(String txnId, String? category) async {
    final box = await _openBox();
    final existing = box.get(txnId);
    if (existing == null) return;
    final updated = Map<dynamic, dynamic>.from(existing);
    final trimmed = category?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      updated.remove('customCategory');
    } else {
      updated['customCategory'] = trimmed;
    }
    await box.put(txnId, updated);
  }

  Future<void> updateConversionMode(String txnId, String mode) async {
    final box = await _openBox();
    final existing = box.get(txnId);
    if (existing == null) return;
    final updated = Map<dynamic, dynamic>.from(existing);
    updated['conversionMode'] = mode;
    await box.put(txnId, updated);
  }

  Future<void> clearCache() async {
    final box = await _openBox();
    await box.clear();
  }
}
