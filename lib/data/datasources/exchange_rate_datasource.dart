import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateDatasource {
  static Future<double> fetchUsdToUah(String apiKey) async {
    final url = Uri.parse(
        'https://v6.exchangerate-api.com/v6/$apiKey/pair/USD/UAH');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch exchange rate (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'] as String?;

    if (result != 'success') {
      final errorType = data['error-type'] as String? ?? 'unknown';
      throw Exception(_errorMessage(errorType));
    }

    return (data['conversion_rate'] as num).toDouble();
  }

  static String _errorMessage(String type) {
    return switch (type) {
      'unsupported-code' => 'Unsupported currency code',
      'malformed-request' => 'Malformed request',
      'invalid-key' => 'Invalid API key',
      'inactive-account' => 'Account not confirmed',
      'quota-reached' => 'Monthly request quota reached',
      _ => 'Unknown error: $type',
    };
  }
}
