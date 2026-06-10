import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:bybit_card_tracker/core/constants/api_constants.dart';
import 'package:bybit_card_tracker/core/error/failures.dart';
import 'package:bybit_card_tracker/core/utils/network_error_messages.dart';
import 'package:bybit_card_tracker/data/models/api_response_model.dart';
import 'package:bybit_card_tracker/data/models/transaction_model.dart';

abstract class BybitRemoteDataSource {
  /// Fetches all card transactions from the asset-records endpoint.
  Future<List<TransactionModel>> fetchAllTransactions({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });

  /// Fetches reward point activity from the points-records endpoint.
  Future<List<TransactionModel>> fetchAllRewardPoints({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });
}

class BybitRemoteDataSourceImpl implements BybitRemoteDataSource {
  final http.Client client;

  const BybitRemoteDataSourceImpl({required this.client});

  // ── Asset Records (main transaction source) ──────────────────────────

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
      final json = await _postWithRetry(
        apiKey: apiKey,
        apiSecret: apiSecret,
        url: '$baseUrl${ApiConstants.assetTransactionRecords}',
        body: {
          'limit': pageSize,
          'page': page,
          // Only fetch cleared transactions; authorization holds are separate.
          'type': 'SIDE_QUERY_AUTH',
        },
      );

      final result = (json['result'] as Map<String, dynamic>?) ?? {};
      final dataList = (result['data'] as List?) ?? [];

      if (dataList.isEmpty) break;

      allTransactions.addAll(
        dataList.map(
          (e) => TransactionModel.fromJson(e as Map<String, dynamic>),
        ),
      );

      final totalCount = result['totalCount'] as int? ?? 0;
      if (allTransactions.length >= totalCount || dataList.length < pageSize) {
        break;
      }

      page++;
    }

    return allTransactions;
  }

  // ── Reward Point Records (bonus activity) ────────────────────────────

  @override
  Future<List<TransactionModel>> fetchAllRewardPoints({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    final allRecords = <TransactionModel>[];
    var page = 1;
    const pageSize = 10; // Points endpoint max is 10–50

    while (true) {
      final json = await _postWithRetry(
        apiKey: apiKey,
        apiSecret: apiSecret,
        url: '$baseUrl${ApiConstants.rewardPointRecords}',
        body: {'pageSize': pageSize, 'pageNo': page},
      );

      final result = (json['result'] as Map<String, dynamic>?) ?? {};
      final dataList = (result['data'] as List?) ?? [];

      if (dataList.isEmpty) break;

      allRecords.addAll(
        dataList.map(
          (e) => TransactionModel.fromJson(e as Map<String, dynamic>),
        ),
      );

      if (dataList.length < pageSize) break;

      page++;
    }

    return allRecords;
  }

  // ── Shared POST + retry logic ─────────────────────────────────────────

  Future<Map<String, dynamic>> _postWithRetry({
    required String apiKey,
    required String apiSecret,
    required String url,
    required Map<String, dynamic> body,
  }) async {
    var rateLimitRetries = 0;

    while (true) {
      final String jsonPayload = jsonEncode(body);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      const String recvWindow = ApiConstants.defaultRecvWindow;

      final String paramStr = '$timestamp$apiKey$recvWindow$jsonPayload';
      final Hmac hmac = Hmac(sha256, utf8.encode(apiSecret));
      final Digest signature = hmac.convert(utf8.encode(paramStr));

      final headers = {
        'X-BAPI-API-KEY': apiKey,
        'X-BAPI-TIMESTAMP': timestamp,
        'X-BAPI-SIGN': signature.toString(),
        'X-BAPI-RECV-WINDOW': recvWindow,
        'Content-Type': 'application/json',
        'User-Agent': 'bybit-skill/1.4.2',
        'X-Referer': 'bybit-skill',
      };

      final uri = Uri.parse(url);
      final http.Response response;

      try {
        response = await client.post(uri, headers: headers, body: jsonPayload);
      } catch (e) {
        throw NetworkFailure(
          NetworkErrorMessages.format(e, host: uri.host),
          host: uri.host,
        );
      }

      if (response.statusCode == 403) throw const GeoRestrictionFailure();

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel.fromJson(json);

      if (apiResponse.retCode == 10006 ||
          apiResponse.retCode == 10014 ||
          response.statusCode == 429) {
        if (rateLimitRetries < 3) {
          rateLimitRetries++;
          await Future.delayed(Duration(milliseconds: 1500 * rateLimitRetries));
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
