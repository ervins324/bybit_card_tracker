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
    const pageSize = ApiConstants.defaultPageSize;

    // First request to get total page count
    final firstPageJson = await _fetchSinglePage(
      page: 1,
      pageSize: pageSize,
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    final apiResponse = ApiResponseModel.fromJson(firstPageJson);
    final resultData = apiResponse.result;
    final totalCount = resultData['totalCount'] as int? ?? 0;
    final dataList = (resultData['data'] as List?) ?? [];

    if (dataList.isNotEmpty) {
      allTransactions.addAll(
        dataList.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)),
      );
    }

    if (dataList.isEmpty || totalCount <= pageSize) {
      return allTransactions;
    }

    // Calculate remaining pages
    final totalPages = (totalCount + pageSize - 1) ~/ pageSize;
    final remainingPages = List.generate(
      totalPages - 1,
      (index) => index + 2,
    );

    if (remainingPages.isEmpty) {
      return allTransactions;
    }

    // Fetch all remaining pages in parallel (max 3 concurrent requests to respect rate limits)
    final futures = remainingPages.map((page) => _fetchSinglePage(
          page: page,
          pageSize: pageSize,
          apiKey: apiKey,
          apiSecret: apiSecret,
          baseUrl: baseUrl,
        ));

    // Use batching to avoid overwhelming rate limits: fetch 3 pages at a time
    final batchSize = 3;
    for (int i = 0; i < futures.length; i += batchSize) {
      final batch = futures.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch);

      for (final json in batchResults) {
        final response = ApiResponseModel.fromJson(json);
        final data = (response.result['data'] as List?) ?? [];
        if (data.isNotEmpty) {
          allTransactions.addAll(
            data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)),
          );
        }
      }
    }

    return allTransactions;
  }

  /// Fetches a single page with rate limit retry logic.
  Future<Map<String, dynamic>> _fetchSinglePage({
    required int page,
    required int pageSize,
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    var rateLimitRetries = 0;
    const maxRetries = 3;

    while (true) {
      final requestBody = <String, dynamic>{
        'pageSize': pageSize,
        'pageNo': page,
      };

      final String jsonPayload = jsonEncode(requestBody);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      const String recvWindow = '5000';

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

      final uri = Uri.parse('$baseUrl${ApiConstants.transactionRecords}');

      final http.Response response;
      try {
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

      // Handle rate limiting with optimized retry
      if (apiResponse.retCode == 10006 ||
          apiResponse.retCode == 10014 ||
          response.statusCode == 429) {
        if (rateLimitRetries < maxRetries) {
          rateLimitRetries++;
          // Fixed 500ms delay per retry instead of exponential
          await Future.delayed(Duration(milliseconds: 500 * rateLimitRetries));
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

      return json;
    }
  }
}
