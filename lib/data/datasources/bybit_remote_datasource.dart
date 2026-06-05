import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:bybit_card_tracker/core/constants/api_constants.dart';
import 'package:bybit_card_tracker/core/error/failures.dart';
import 'package:bybit_card_tracker/core/utils/network_error_messages.dart';
import 'package:bybit_card_tracker/data/models/api_response_model.dart';
import 'package:bybit_card_tracker/data/models/transaction_model.dart';

abstract class BybitRemoteDataSource {
  Future<List<TransactionModel>> fetchAllTransactions({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });
}

class BybitRemoteDataSourceImpl implements BybitRemoteDataSource {
  final http.Client client;

  const BybitRemoteDataSourceImpl({required this.client});

  @override
  Future<List<TransactionModel>> fetchAllTransactions({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    final allTransactions = <TransactionModel>[];
    var page = 1;
    const pageSize = ApiConstants.defaultPageSize;

    while (true) {
      var rateLimitRetries = 0;
      Map<String, dynamic> jsonResponse;

      while (true) {
        // 1. Формуємо правильні імена параметрів пагінації для Reward Points
        final requestBody = <String, dynamic>{
          'pageSize': pageSize,
          'pageNo': page,
        };

        // 2. Створюємо компактний JSON без пробілів (критично для підпису)
        final String jsonPayload = jsonEncode(requestBody);

        // 3. Пряма генерація заголовків та підпису HMAC-SHA256 з робочого файлу
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        const String recvWindow = '5000';

        // Рядок підпису для POST: timestamp + apiKey + recvWindow + jsonBody
        final String paramStr = '$timestamp$apiKey$recvWindow$jsonPayload';

        final List<int> secretBytes = utf8.encode(apiSecret);
        final List<int> messageBytes = utf8.encode(paramStr);
        final Hmac hmac = Hmac(sha256, secretBytes);
        final Digest signature = hmac.convert(messageBytes);

        final Map<String, String> headers = {
          'X-BAPI-API-KEY': apiKey,
          'X-BAPI-TIMESTAMP': timestamp,
          'X-BAPI-SIGN': signature.toString(),
          'X-BAPI-RECV-WINDOW': recvWindow,
          'Content-Type': 'application/json',
          'User-Agent': 'bybit-skill/1.4.2',
          'X-Referer': 'bybit-skill',
        };

        // 4. Використовуємо ваш шлях з ApiConstants
        final uri = Uri.parse('$baseUrl${ApiConstants.transactionRecords}');

        final http.Response response;
        try {
          // Робимо POST запит із передачею jsonPayload у body
          response = await client.post(
            uri,
            headers: headers,
            body: jsonPayload,
          );
        } catch (e) {
          final host = uri.host;
          throw NetworkFailure(
            NetworkErrorMessages.format(e, host: host),
            host: host,
          );
        }

        if (response.statusCode == 403) {
          throw const GeoRestrictionFailure();
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponseModel.fromJson(json);

        // Обробка лімітів запитів (Rate limit)
        if (apiResponse.retCode == 10006 ||
            apiResponse.retCode == 10014 ||
            response.statusCode == 429) {
          if (rateLimitRetries < 3) {
            rateLimitRetries++;
            await Future.delayed(
              Duration(milliseconds: 1500 * rateLimitRetries),
            );
            continue;
          }
          throw ServerFailure(
            'Rate limit exceeded. ${apiResponse.retMsg}',
            retCode: apiResponse.retCode,
            statusCode: response.statusCode,
          );
        }

        if (!apiResponse.isSuccess) {
          throw ServerFailure(apiResponse.retMsg, retCode: apiResponse.retCode);
        }

        jsonResponse = json;
        break;
      }

      final apiResponse = ApiResponseModel.fromJson(jsonResponse);
      final resultData = apiResponse.result;
      final dataList = (resultData['data'] as List?) ?? [];

      if (dataList.isEmpty) break;

      // Мапимо отримані записи балів у ваші моделі TransactionModel
      allTransactions.addAll(
        dataList.map(
          (e) => TransactionModel.fromJson(e as Map<String, dynamic>),
        ),
      );

      if (dataList.length < pageSize) break;

      page++;
    }

    return allTransactions;
  }
}
