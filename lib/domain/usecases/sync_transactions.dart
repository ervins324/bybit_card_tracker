import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';
import 'package:bybit_card_tracker/domain/repositories/transaction_repository.dart';

/// Use case: Fetch transactions from the Bybit API and cache them locally.
class SyncTransactions {
  final TransactionRepository repository;

  const SyncTransactions(this.repository);

  Future<List<TransactionEntity>> call({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) {
    return repository.syncTransactions(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );
  }
}
