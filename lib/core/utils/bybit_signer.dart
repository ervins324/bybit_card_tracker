import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Implements Bybit HMAC-SHA256 request signing with server time sync.
class BybitSigner {
  BybitSigner._();

  static const String serverTimeEndpoint = '/v5/market/time';
  // Зменшено до 5000 (стандарт Bybit, завелике вікно часто викликає param_illegal на бойовому сервері)
  static const String _recvWindow = '5000';
  static int _serverTimeOffset = 0;

  /// Updates the internal time offset by comparing local time to Bybit server time.
  static void updateOffset(int serverTimeMs) {
    _serverTimeOffset = serverTimeMs - DateTime.now().millisecondsSinceEpoch;
  }

  /// Gets the synchronized timestamp.
  static String get timestamp =>
      (DateTime.now().millisecondsSinceEpoch + _serverTimeOffset).toString();

  /// Generates the HMAC-SHA256 signature for a request.
  static String sign({
    required String timestamp,
    required String apiKey,
    required String body,
    required String apiSecret,
  }) {
    // Четкое соответствие документации v5: timestamp + api_key + recv_window + jsonBodyString
    final stringToSign = '$timestamp$apiKey$_recvWindow$body';

    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    final digest = hmac.convert(utf8.encode(stringToSign));
    return digest.toString(); // Должен получиться строчный HEX
  }

  /// Builds the full set of authenticated headers for a Bybit API call.
  static Map<String, String> generateHeaders({
    required String apiKey,
    required String apiSecret,
    required String body,
  }) {
    final now = timestamp;
    final signature = sign(
      timestamp: now,
      apiKey: apiKey,
      body: body,
      apiSecret: apiSecret,
    );

    return {
      'X-BAPI-API-KEY': apiKey,
      'X-BAPI-TIMESTAMP': now,
      'X-BAPI-SIGN': signature,
      'X-BAPI-SIGN-TYPE': '2',
      'X-BAPI-RECV-WINDOW': _recvWindow,
      'Content-Type': 'application/json',
    };
  }
}
