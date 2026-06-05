import 'package:bybit_card_tracker/data/datasources/bybit_remote_datasource.dart';
import 'package:bybit_card_tracker/data/datasources/transaction_local_datasource.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';
import 'package:bybit_card_tracker/domain/repositories/transaction_repository.dart';

/// Concrete repository that coordinates remote (Bybit API) and local (Hive) data.
class TransactionRepositoryImpl implements TransactionRepository {
  final BybitRemoteDataSource remoteDatasource;
  final TransactionLocalDatasource localDatasource;

  const TransactionRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<List<TransactionEntity>> syncTransactions({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    // 1. Fetch all pages from the Bybit API
    final models = await remoteDatasource.fetchAllTransactions(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    // 2. Cache them locally (upserts by txnId)
    await localDatasource.cacheTransactions(models);

    // 3. Return as domain entities
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<TransactionEntity>> getCachedTransactions() async {
    final models = await localDatasource.getCachedTransactions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> clearCache() async {
    await localDatasource.clearCache();
  }
}
