/// Bybit API constants and endpoint configuration.
class ApiConstants {
  ApiConstants._();

  // ── Base URLs ──────────────────────────────────────────────────────────
  static const String mainnetBaseUrl = 'https://api.bybit.com';
  static const String bytickMirrorUrl = 'https://api.bytick.com';

  /// Regional mainnet endpoints the user can choose from.
  static const Map<String, String> regionalEndpoints = {
    'Global (Default)': mainnetBaseUrl,
    'Global Mirror (bytick)': bytickMirrorUrl,
    'Netherlands': 'https://api.bybit.nl',
    'Turkey': 'https://api.bybit.tr',
    'Kazakhstan': 'https://api.bybit.kz',
    'Georgia': 'https://api.bybitgeorgia.ge',
    'UAE': 'https://api.bybit.ae',
    'Indonesia': 'https://api.bybit.id',
  };

  // ── Endpoints ──────────────────────────────────────────────────────────
  static const String rewardPointRecords = '/v5/card/reward/points/records';
  static const String assetTransactionRecords =
      '/v5/card/transaction/query-asset-records';

  /// Primary data source: asset records (includes mccCode, full transaction data).
  /// Reward point records are fetched separately for bonus activity.
  static const String transactionRecords = assetTransactionRecords;

  // ── Defaults ───────────────────────────────────────────────────────────
  static const String defaultRecvWindow = '5000';
  static const int defaultPageSize = 100;
  static const int maxPageSize = 500;
}
