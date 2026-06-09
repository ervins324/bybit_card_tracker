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
    // 1. Fetch all pages from the Bybit API
    final models = await remoteDatasource.fetchAllTransactions(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    // 2. Cache them locally (upserts by txnId)
    await localDatasource.cacheTransactions(models);

    // 3. Return as domain entities
    return _deduplicateCardRecords(models).map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<TransactionEntity>> getCachedTransactions() async {
    final models = await localDatasource.getCachedTransactions();
    return _deduplicateCardRecords(models).map((m) => m.toEntity()).toList();
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

  List<TransactionModel> _deduplicateCardRecords(
    List<TransactionModel> models,
  ) {
    final selectedByKey = <String, TransactionModel>{};
    final passthrough = <TransactionModel>[];

    for (final model in models) {
      if (!model.isCardPurchase) {
        passthrough.add(model);
        continue;
      }

      final key = _cardDuplicateKey(model);
      if (key == null) {
        passthrough.add(model);
        continue;
      }

      final existing = selectedByKey[key];
      if (existing == null || _isBetterCardRecord(model, existing)) {
        selectedByKey[key] = model;
      }
    }

    return [...passthrough, ...selectedByKey.values];
  }

  String? _cardDuplicateKey(TransactionModel model) {
    final orderNo = _normalized(model.orderNo);
    if (orderNo != null) return 'order:$orderNo';

    final merchant = _normalized(model.merchName);
    final amount = _normalizedAmount(model.basicAmount ?? model.transactionAmount);
    final currency = _normalized(model.basicCurrency ?? model.transactionCurrency);
    final card = _normalized(model.cardToken) ?? _normalized(model.pan4);
    final createdAt = model.txnCreate;

    if (merchant == null ||
        amount == null ||
        currency == null ||
        card == null ||
        createdAt == null) {
      return null;
    }

    // Auth and final purchase rows for the same card spend can differ only by
    // MCC/category data. Bucket by minute to avoid double-counting that pair.
    final minuteBucket = createdAt ~/ Duration.millisecondsPerMinute;
    return 'fingerprint:$merchant|$amount|$currency|$card|$minuteBucket';
  }

  bool _isBetterCardRecord(
    TransactionModel candidate,
    TransactionModel current,
  ) {
    final candidateScore = _cardRecordScore(candidate);
    final currentScore = _cardRecordScore(current);
    if (candidateScore != currentScore) {
      return candidateScore > currentScore;
    }

    return (candidate.txnCreate ?? 0) > (current.txnCreate ?? 0);
  }

  int _cardRecordScore(TransactionModel model) {
    var score = 0;
    final side = TransactionSide.fromApi(model.side);
    final status = TransactionStatus.fromApi(model.tradeStatus);

    if (_normalized(model.merchCategoryDesc) != null) score += 8;
    if (side == TransactionSide.transaction) score += 4;
    if (status == TransactionStatus.completed) score += 3;
    if (_normalized(model.declinedReason) == null) score += 1;

    return score;
  }

  String? _normalized(String? value) {
    final text = value?.trim().toLowerCase();
    return text?.isEmpty ?? true ? null : text;
  }

  String? _normalizedAmount(String? value) {
    final parsed = double.tryParse(value ?? '');
    return parsed?.abs().toStringAsFixed(8);
  }
}
