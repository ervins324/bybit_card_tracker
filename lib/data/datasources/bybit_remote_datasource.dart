import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:bybit_card_tracker/core/constants/api_constants.dart';
import 'package:bybit_card_tracker/core/error/failures.dart';
import 'package:bybit_card_tracker/core/utils/network_error_messages.dart';
import 'package:bybit_card_tracker/data/models/api_response_model.dart';
import 'package:bybit_card_tracker/data/models/transaction_model.dart';

abstract class BybitRemoteDataSource {
  Future<List<TransactionModel>> getAssetRecords({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });

  Future<List<TransactionModel>> getRewardPointRecords({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });

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
  Future<List<TransactionModel>> getAssetRecords({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    return _fetchPagesPagination(
      endpoint: ApiConstants.assetTransactionRecords,
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
      extraParams: {'type': 'SIDE_QUERY_AUTH', 'statusCode': '1'},
    );
  }

  @override
  Future<List<TransactionModel>> getRewardPointRecords({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    return _fetchPagesPagination(
      endpoint: ApiConstants.rewardPointRecords,
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );
  }

  @override
  Future<List<TransactionModel>> fetchAllTransactions({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    final assetRecords = await getAssetRecords(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    await Future.delayed(const Duration(seconds: 1));

    final rewardRecords = await getRewardPointRecords(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    final Map<String, TransactionModel> mergedTransactions = {};

    for (final record in rewardRecords) {
      mergedTransactions[record.txnId] = record;
    }

    for (final record in assetRecords) {
      final cleanMerchant = (record.merchName ?? '').trim().toLowerCase();
      final amountKey = record.basicAmount ?? record.transactionAmount ?? '0';
      final rawTime = record.txnCreate ?? 0;
      final timeMinutes = rawTime ~/ 60000;

      final uniqueKey = '${timeMinutes}_${amountKey}_$cleanMerchant';

      if (mergedTransactions.containsKey(uniqueKey)) {
        final existing = mergedTransactions[uniqueKey]!;
        final existingMcc = existing.merchCategoryDesc ?? '';
        final newMcc = record.merchCategoryDesc ?? '';

        if (existingMcc.isEmpty && newMcc.isNotEmpty) {
          mergedTransactions[uniqueKey] = record;
        }
      } else {
        if (!mergedTransactions.containsKey(record.txnId)) {
          mergedTransactions[uniqueKey] = record;
        }
      }
    }

    return mergedTransactions.values.toList();
  }

  Future<List<TransactionModel>> _fetchPagesPagination({
    required String endpoint,
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
    Map<String, dynamic>? extraParams,
  }) async {
    final allTransactions = <TransactionModel>[];
    const pageSize = ApiConstants.defaultPageSize;

    final firstPageJson = await _fetchSinglePage(
      endpoint: endpoint,
      page: 1,
      pageSize: pageSize,
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
      extraParams: extraParams,
    );

    final apiResponse = ApiResponseModel.fromJson(firstPageJson);
    final resultData = apiResponse.result;
    final totalCount = resultData['totalCount'] as int? ?? 0;
    final dataList = (resultData['data'] as List?) ?? [];

    if (dataList.isNotEmpty) {
      allTransactions.addAll(
        dataList.map(
          (e) => TransactionModel.fromJson(e as Map<String, dynamic>),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 1));

    if (dataList.isEmpty || totalCount <= pageSize) {
      return allTransactions;
    }

    final totalPages = (totalCount + pageSize - 1) ~/ pageSize;
    final remainingPages = List.generate(totalPages - 1, (index) => index + 2);

    for (final page in remainingPages) {
      final json = await _fetchSinglePage(
        endpoint: endpoint,
        page: page,
        pageSize: pageSize,
        apiKey: apiKey,
        apiSecret: apiSecret,
        baseUrl: baseUrl,
        extraParams: extraParams,
      );

      final response = ApiResponseModel.fromJson(json);
      final data = (response.result['data'] as List?) ?? [];
      if (data.isNotEmpty) {
        allTransactions.addAll(
          data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)),
        );
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    return allTransactions;
  }

  Future<Map<String, dynamic>> _fetchSinglePage({
    required String endpoint,
    required int page,
    required int pageSize,
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
    Map<String, dynamic>? extraParams,
  }) async {
    var rateLimitRetries = 0;
    const maxRetries = 3;

    while (true) {
      final requestBody = <String, dynamic>{
        'pageSize': pageSize,
        'pageNo': page,
        if (extraParams != null) ...extraParams,
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
        'User-Agent': 'bybit-card-tracker/1.0.0',
        'X-Referer': 'bybit-card-tracker',
      };

      final uri = Uri.parse('$baseUrl$endpoint');

      final http.Response response;
      try {
        response = await client.post(uri, headers: headers, body: jsonPayload);
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

      if (apiResponse.retCode == 10006 ||
          apiResponse.retCode == 10014 ||
          response.statusCode == 429) {
        if (rateLimitRetries < maxRetries) {
          rateLimitRetries++;
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
