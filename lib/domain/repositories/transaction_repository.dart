import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';

/// Abstract repository interface for the domain layer.
///
/// The data layer provides the concrete implementation.
abstract class TransactionRepository {
  /// Fetches transactions from the Bybit API, caches them locally,
  /// and returns the full list.
  Future<List<TransactionEntity>> syncTransactions({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });

  /// Returns transactions from the local Hive cache.
  Future<List<TransactionEntity>> getCachedTransactions();

  /// Clears all locally cached transactions.
  Future<void> clearCache();
}
