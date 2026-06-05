import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:bybit_card_tracker/data/datasources/bybit_remote_datasource.dart';
import 'package:bybit_card_tracker/data/datasources/transaction_local_datasource.dart';
import 'package:bybit_card_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';
import 'package:bybit_card_tracker/domain/repositories/transaction_repository.dart';
import 'package:bybit_card_tracker/presentation/providers/credentials_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';
import 'package:bybit_card_tracker/core/constants/merchant_categories.dart';

// ── Dependency providers ─────────────────────────────────────────────────

final _httpClientProvider = Provider<http.Client>((_) => http.Client());

final _remoteDataSourceProvider = Provider<BybitRemoteDataSource>((ref) {
  return BybitRemoteDataSourceImpl(client: ref.watch(_httpClientProvider));
});

final _localDataSourceProvider = Provider<TransactionLocalDatasource>((_) {
  return TransactionLocalDatasource();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    remoteDatasource: ref.watch(_remoteDataSourceProvider),
    localDatasource: ref.watch(_localDataSourceProvider),
  );
});

// ── Transaction state ────────────────────────────────────────────────────

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<TransactionEntity>>(
  TransactionNotifier.new,
);

/// Manages the list of transactions — loads from cache on start,
/// and syncs from the Bybit API on demand.
class TransactionNotifier extends AsyncNotifier<List<TransactionEntity>> {
  @override
  Future<List<TransactionEntity>> build() async {
    // On startup, try loading from cache for instant display.
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getCachedTransactions();
  }

  /// Triggers a full sync from the Bybit API.
  ///
  /// The previous data stays visible while loading, then gets replaced.
  Future<void> sync() async {
    final credentials = ref.read(credentialsProvider).valueOrNull;
    if (credentials == null || !credentials.isValid) {
      state = AsyncError(
        Exception('API credentials not configured.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading<List<TransactionEntity>>()
        .copyWithPrevious(state);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final transactions = await repo.syncTransactions(
        apiKey: credentials.apiKey,
        apiSecret: credentials.apiSecret,
        baseUrl: credentials.baseUrl,
      );
      state = AsyncData(transactions);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Clears the cache and resets state.
  Future<void> clearData() async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.clearCache();
    state = const AsyncData([]);
  }
}

// ── Filtered & enriched views ────────────────────────────────────────────

TransactionEntity _withResolvedCategory(
  TransactionEntity entity,
  List<MerchantCategoryRule> userRules,
) {
  if (!entity.isCardPurchase) return entity;
  return entity.copyWith(
    category: MerchantCategories.resolve(
      entity.merchantName,
      apiCategory: entity.category,
      userRules: userRules,
    ),
  );
}

/// Card purchases only, with user category rules applied.
final cardTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final txnState = ref.watch(transactionProvider);
  final userRules = ref.watch(settingsProvider).categoryRules;
  return txnState.valueOrNull
          ?.where((tx) => tx.isCardPurchase)
          .map((tx) => _withResolvedCategory(tx, userRules))
          .toList() ??
      [];
});

/// System bonus / reward point activity (not card purchases).
final bonusTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  return ref
          .watch(transactionProvider)
          .valueOrNull
          ?.where((tx) => tx.isBonus)
          .toList() ??
      [];
});

final cardTransactionsAsyncProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  return ref.watch(transactionProvider).whenData(
        (list) => ref.watch(cardTransactionsProvider),
      );
});

final bonusTransactionsAsyncProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  return ref.watch(transactionProvider).whenData(
        (list) => ref.watch(bonusTransactionsProvider),
      );
});
