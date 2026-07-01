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
    void Function(List<TransactionEntity> partials)? onProgress,
  }) async {
    final assetRecords = await remoteDatasource.fetchAllTransactions(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
      onPageFetched: (models) async {
        await localDatasource.cacheTransactions(models);
        onProgress?.call(models.map((m) => m.toEntity()).toList());
      },
    );
    await Future.delayed(const Duration(seconds: 1));
    final pointRecords = await remoteDatasource.fetchAllRewardPoints(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
      onPageFetched: (models) async {
        // Here we cache the raw models as they come in.
        // We will filter out duplicates from asset records below,
        // but it's safe to cache them temporarily since the keys will match
        // or be distinct and get handled on query.
        await localDatasource.cacheTransactions(models);
        onProgress?.call(models.map((m) => m.toEntity()).toList());
      },
    );

    final assetIds = assetRecords.map((asset) => asset.txnId).toSet();
    final filteredPointRecords = pointRecords.where((pointRecord) {
      if (assetIds.contains(pointRecord.txnId)) return false;
      final isRefund = pointRecord.isRefundRecord;
      final amountStr =
          pointRecord.basicAmount ?? pointRecord.transactionAmount ?? '';
      final double amount = double.tryParse(amountStr) ?? 0.0;
      final isPureBonus = pointRecord.point != null && amount == 0.0;
      return isRefund || isPureBonus;
    }).toList();

    final finalModels = [...assetRecords, ...filteredPointRecords];
    await localDatasource.cacheTransactions(finalModels);
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
  Future<void> updateConversionMode(String txnId, String mode) async {
    await localDatasource.updateConversionMode(txnId, mode);
  }

  @override
  Future<TransactionModel?> getTransactionById(String txnId) async {
    return localDatasource.getById(txnId);
  }
}
