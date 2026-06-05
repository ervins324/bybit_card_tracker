/// Wrapper model for Bybit's standardized API response format.
///
/// Every API response has: retCode, retMsg, result, retExtInfo, time.
class ApiResponseModel {
  final int retCode;
  final String retMsg;
  final Map<String, dynamic> result;
  final int time;

  const ApiResponseModel({
    required this.retCode,
    required this.retMsg,
    required this.result,
    required this.time,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      retCode: json['retCode'] as int? ?? -1,
      retMsg: json['retMsg']?.toString() ?? 'Unknown error',
      result: (json['result'] as Map<String, dynamic>?) ?? {},
      time: json['time'] as int? ?? 0,
    );
  }

  /// Whether the API call was successful.
  bool get isSuccess => retCode == 0;
}
