import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';
import 'package:bybit_card_tracker/domain/repositories/transaction_repository.dart';

/// Use case: Load transactions from the local Hive cache.
class GetCachedTransactions {
  final TransactionRepository repository;

  const GetCachedTransactions(this.repository);

  Future<List<TransactionEntity>> call() {
    return repository.getCachedTransactions();
  }
}
