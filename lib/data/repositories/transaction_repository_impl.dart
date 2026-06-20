import 'package:bybit_card_tracker/data/datasources/bybit_remote_datasource.dart';
import 'package:bybit_card_tracker/data/datasources/transaction_local_datasource.dart';
import 'package:bybit_card_tracker/data/models/transaction_model.dart';
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
    final assetRecords = await remoteDatasource.fetchAllTransactions(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    await Future.delayed(const Duration(seconds: 1));

    final pointRecords = await remoteDatasource.fetchAllRewardPoints(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    // 2. Filter out duplicates and keep only standalone refunds/bonuses from points
    // Create a set of existing asset transaction IDs for O(1) lookup
    final assetIds = assetRecords.map((asset) => asset.txnId).toSet();

    final filteredPointRecords = pointRecords.where((pointRecord) {
      // Если транзакция уже есть в Asset Records, полностью игнорируем её из Point Records
      if (assetIds.contains(pointRecord.txnId)) {
        return false;
      }

      // Если ID уникальный, проверяем, является ли это рефандом или бонусом
      final isRefund = pointRecord.isRefundRecord;
      // final isPureBonus =
      //     pointRecord.point != null &&
      //     (pointRecord.basicAmount == null ||
      //         pointRecord.transactionAmount == null);
      final amountStr =
          pointRecord.basicAmount ?? pointRecord.transactionAmount ?? '';
      final double amount = double.tryParse(amountStr) ?? 0.0;

      final isPureBonus = pointRecord.point != null && amount == 0.0;

      return isRefund || isPureBonus;
    }).toList();

    // Combine asset records and valid unique point records without any merging
    final finalModels = [...assetRecords, ...filteredPointRecords];

    // 3. Cache them locally (upserts by txnId)
    await localDatasource.cacheTransactions(finalModels);

    // 4. Return as domain entities
    return finalModels.map((m) => m.toEntity()).toList()
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

  @override
  Future<void> updateTransactionCategory(String txnId, String? category) async {
    await localDatasource.updateCategory(txnId, category);
  }

  @override
  Future<TransactionModel?> getTransactionById(String txnId) async {
    return localDatasource.getById(txnId);
  }
}
