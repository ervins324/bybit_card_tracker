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
    );
    await Future.delayed(const Duration(seconds: 1));
    final pointRecords = await remoteDatasource.fetchAllRewardPoints(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    final assetIds = assetRecords.map((asset) => asset.txnId).toSet();
    final assetOrderNos = assetRecords
        .map((asset) => asset.orderNo)
        .where((o) => o != null && o.isNotEmpty)
        .toSet();

    final deduplicatedPointRecords = pointRecords.where((pointRecord) {
      final cleanId = pointRecord.txnId.startsWith('rp_')
          ? pointRecord.txnId.substring(3)
          : pointRecord.txnId;
      if (pointRecord.isRefundRecord &&
          (assetIds.contains(pointRecord.txnId) ||
              assetIds.contains(cleanId) ||
              (pointRecord.orderNo != null &&
                  assetOrderNos.contains(pointRecord.orderNo)))) {
        return false;
      }
      return true;
    }).toList();

    final finalModels = [...assetRecords, ...deduplicatedPointRecords];
    await localDatasource.replaceCache(finalModels);
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
