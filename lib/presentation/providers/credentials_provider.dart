import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:bybit_card_tracker/core/constants/api_constants.dart';

/// Holds the user's Bybit API credentials.
class Credentials {
  final String apiKey;
  final String apiSecret;
  final String baseUrl;

  const Credentials({
    required this.apiKey,
    required this.apiSecret,
    required this.baseUrl,
  });

  bool get isValid => apiKey.isNotEmpty && apiSecret.isNotEmpty;
}

// ── Secure storage keys ──────────────────────────────────────────────────
const _kApiKey = 'bybit_api_key';
const _kApiSecret = 'bybit_api_secret';
const _kBaseUrl = 'bybit_base_url';

/// Provider for the credentials notifier.
final credentialsProvider =
    AsyncNotifierProvider<CredentialsNotifier, Credentials?>(
  CredentialsNotifier.new,
);

/// Convenience provider: `true` if credentials have been saved.
final hasCredentialsProvider = Provider<bool>((ref) {
  final creds = ref.watch(credentialsProvider).valueOrNull;
  return creds?.isValid ?? false;
});

/// Manages API credentials via `flutter_secure_storage`.
class CredentialsNotifier extends AsyncNotifier<Credentials?> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<Credentials?> build() async {
    return _load();
  }

  Future<Credentials?> _load() async {
    final apiKey = await _storage.read(key: _kApiKey);
    final apiSecret = await _storage.read(key: _kApiSecret);
    final baseUrl = await _storage.read(key: _kBaseUrl);

    if (apiKey == null || apiSecret == null) return null;
    if (apiKey.isEmpty || apiSecret.isEmpty) return null;

    return Credentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl ?? ApiConstants.mainnetBaseUrl,
    );
  }

  /// Persists credentials to secure storage.
  Future<void> save({
    required String apiKey,
    required String apiSecret,
    String baseUrl = ApiConstants.mainnetBaseUrl,
  }) async {
    await _storage.write(key: _kApiKey, value: apiKey);
    await _storage.write(key: _kApiSecret, value: apiSecret);
    await _storage.write(key: _kBaseUrl, value: baseUrl);

    state = AsyncData(Credentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    ));
  }

  /// Clears stored credentials.
  Future<void> clear() async {
    await _storage.delete(key: _kApiKey);
    await _storage.delete(key: _kApiSecret);
    await _storage.delete(key: _kBaseUrl);
    state = const AsyncData(null);
  }
}
