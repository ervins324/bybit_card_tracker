import 'package:bybit_card_tracker/core/constants/bonus_types.dart';
import 'package:bybit_card_tracker/core/constants/merchant_categories.dart';
import 'package:bybit_card_tracker/domain/entities/transaction_entity.dart';

/// Data model for Bybit card transactions and reward point records.
///
/// Handles JSON parsing from the API and Map serialization for Hive storage.
class TransactionModel {
  final String txnId;
  final String? orderNo;
  final String? merchName;
  final String? merchCategoryDesc;
  final String? mccCode;
  final String? side;
  final String? tradeStatus;
  final String? basicAmount;
  final String? basicCurrency;
  final String? transactionAmount;
  final String? transactionCurrency;
  final int? txnCreate;
  final String? declinedReason;
  final String? status;
  final String? pan4;
  final String? pan6;
  final String? cardToken;
  final int? point;
  final String? rewardSide;
  final String? rewardType;
  final String? rewardSubType;
  final String? customCategory;
  final Map<String, dynamic> rawApiData;

  const TransactionModel({
    required this.txnId,
    this.orderNo,
    this.merchName,
    this.merchCategoryDesc,
    this.mccCode,
    this.side,
    this.tradeStatus,
    this.basicAmount,
    this.basicCurrency,
    this.transactionAmount,
    this.transactionCurrency,
    this.txnCreate,
    this.declinedReason,
    this.status,
    this.pan4,
    this.pan6,
    this.cardToken,
    this.point,
    this.rewardSide,
    this.rewardType,
    this.rewardSubType,
    this.customCategory,
    this.rawApiData = const {},
  });

  double get _spendAmount =>
      double.tryParse(basicAmount ?? transactionAmount ?? '') ?? 0.0;

  bool get isCardPurchase => BonusTypes.isCardTransaction(
    rewardType: rewardType,
    rewardSubType: rewardSubType,
    merchName: merchName,
    spendAmount: _spendAmount,
  );

  bool get isRefundRecord =>
      BonusTypes.isRefund(rewardType: rewardType, rewardSubType: rewardSubType);

  // ── JSON parsing (API response) ─────────────────────────────────────
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final isRewardRecord =
        json.containsKey('point') ||
        (json.containsKey('transactionId') && !json.containsKey('txnId'));

    final txnId =
        json['txnId']?.toString() ??
        json['transactionId']?.toString() ??
        json['bizTxnId']?.toString() ??
        json['bizId']?.toString() ??
        '';

    final rewardSide = isRewardRecord ? json['side']?.toString() : null;

    return TransactionModel(
      txnId: txnId.isNotEmpty
          ? txnId
          : 'rp_${json['createTime'] ?? json['txnCreate']}_${json['merchName']}',
      orderNo: json['orderNo']?.toString() ?? json['outOrderId']?.toString(),
      merchName: json['merchName']?.toString(),
      merchCategoryDesc: json['merchCategoryDesc']?.toString(),
      mccCode: json['mccCode']?.toString(),
      side: isRewardRecord
          ? (BonusTypes.isRefund(
                  rewardType: json['type']?.toString(),
                  rewardSubType: json['subType']?.toString(),
                )
                ? '5'
                : '3')
          : json['side']?.toString(),
      tradeStatus:
          json['tradeStatus']?.toString() ?? (isRewardRecord ? '1' : null),
      basicAmount:
          json['basicAmount']?.toString() ??
          json['transactionAmount']?.toString() ??
          _firstNonZeroAmount(
            json['payFiatAmount'],
            json['transactionCurrencyAmount'],
          ),
      basicCurrency: json['basicCurrency']?.toString(),
      transactionAmount: json['transactionAmount']?.toString(),
      transactionCurrency: json['transactionCurrency']?.toString(),
      txnCreate: _parseInt(
        json['txnCreate'] ?? json['createTime'] ?? json['transactionDate'],
      ),
      declinedReason: json['declinedReason']?.toString(),
      status: json['status']?.toString(),
      pan4: json['pan4']?.toString(),
      pan6: json['pan6']?.toString(),
      cardToken: json['cardToken']?.toString(),
      point: _parseInt(json['point']),
      rewardSide: rewardSide,
      rewardType: json['type']?.toString(),
      rewardSubType: json['subType']?.toString(),
      rawApiData: Map<String, dynamic>.from(json),
    );
  }

  // ── Hive storage (Map serialization) ────────────────────────────────
  Map<String, dynamic> toMap() => {
    'txnId': txnId,
    'orderNo': orderNo,
    'merchName': merchName,
    'merchCategoryDesc': merchCategoryDesc,
    'mccCode': mccCode,
    'side': side,
    'tradeStatus': tradeStatus,
    'basicAmount': basicAmount,
    'basicCurrency': basicCurrency,
    'transactionAmount': transactionAmount,
    'transactionCurrency': transactionCurrency,
    'txnCreate': txnCreate,
    'declinedReason': declinedReason,
    'status': status,
    'pan4': pan4,
    'pan6': pan6,
    'cardToken': cardToken,
    'point': point,
    'rewardSide': rewardSide,
    'rewardType': rewardType,
    'rewardSubType': rewardSubType,
    'customCategory': customCategory,
    'rawApiData': rawApiData,
  };

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel(
      txnId: map['txnId']?.toString() ?? '',
      orderNo: map['orderNo']?.toString(),
      merchName: map['merchName']?.toString(),
      merchCategoryDesc: map['merchCategoryDesc']?.toString(),
      mccCode: map['mccCode']?.toString(),
      side: map['side']?.toString(),
      tradeStatus: map['tradeStatus']?.toString(),
      basicAmount:
          map['basicAmount']?.toString() ??
          map['transactionAmount']?.toString(),
      basicCurrency: map['basicCurrency']?.toString(),
      transactionAmount: map['transactionAmount']?.toString(),
      transactionCurrency: map['transactionCurrency']?.toString(),
      txnCreate: _parseInt(map['txnCreate'] ?? map['createTime']),
      declinedReason: map['declinedReason']?.toString(),
      status: map['status']?.toString(),
      pan4: map['pan4']?.toString(),
      pan6: map['pan6']?.toString(),
      cardToken: map['cardToken']?.toString(),
      point: _parseInt(map['point']),
      rewardSide: map['rewardSide']?.toString(),
      rewardType: map['rewardType']?.toString(),
      rewardSubType: map['rewardSubType']?.toString(),
      customCategory: map['customCategory']?.toString(),
      rawApiData: _parseRawApiData(map['rawApiData']),
    );
  }

  static Map<String, dynamic> _parseRawApiData(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  /// All API fields for the detail view (raw response preferred).
  Map<String, String> get apiFieldsForDisplay {
    final fields = <String, String>{};

    void add(String key, dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      fields[key] = text;
    }

    if (rawApiData.isNotEmpty) {
      for (final entry in rawApiData.entries) {
        add(entry.key, entry.value);
      }
    } else {
      add('transactionId', txnId);
      add('outOrderId', orderNo);
      add('merchName', merchName);
      add('merchCategoryDesc', merchCategoryDesc);
      add('mccCode', mccCode);
      add('basicAmount', basicAmount);
      add('basicCurrency', basicCurrency);
      add('transactionAmount', transactionAmount);
      add('transactionCurrency', transactionCurrency);
      add('createTime', txnCreate);
      add('pan4', pan4);
      add('pan6', pan6);
      add('point', point);
      add('side', rewardSide);
      add('type', rewardType);
      add('subType', rewardSubType);
    }

    return Map.fromEntries(
      fields.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  TransactionEntity _toEntityBase({
    required TransactionRecordType recordType,
    required String merchantName,
    required TransactionSide parsedSide,
    required double signedAmount,
    required TransactionStatus status,
  }) {
    final resolvedCategory = customCategory?.trim().isNotEmpty == true
        ? customCategory!.trim()
        : MerchantCategories.resolve(
            merchName,
            apiCategory: merchCategoryDesc,
            mccCode: mccCode,
          );

    return TransactionEntity(
      id: txnId,
      merchantName: merchantName,
      category: resolvedCategory,
      recordType: recordType,
      amount: signedAmount,
      currency: basicCurrency ?? 'USD',
      dateTime: txnCreate != null
          ? DateTime.fromMillisecondsSinceEpoch(txnCreate!)
          : DateTime.now(),
      status: status,
      side: parsedSide,
      declinedReason: declinedReason,
      pan4: pan4 ?? '****',
      pointAmount: point ?? 0,
      rewardSide: rewardSide,
      rewardType: rewardType,
      rewardSubType: rewardSubType,
      mccCode: mccCode,
      customCategory: customCategory,
      rawApiData: rawApiData,
    );
  }

  // ── Domain mapping ──────────────────────────────────────────────────
  TransactionEntity toEntity() {
    final recordType = isCardPurchase
        ? TransactionRecordType.cardPurchase
        : TransactionRecordType.bonus;

    if (recordType == TransactionRecordType.bonus) {
      return _toEntityBase(
        recordType: recordType,
        merchantName: BonusTypes.describe(
          rewardType: rewardType,
          rewardSubType: rewardSubType,
          rewardSide: rewardSide,
          merchName: merchName,
        ),
        parsedSide: TransactionSide.transaction,
        signedAmount: 0,
        status: TransactionStatus.completed,
      );
    }

    final parsedSide = isRefundRecord
        ? TransactionSide.refund
        : TransactionSide.fromApi(side);
    final rawAmount = _spendAmount;
    final status = tradeStatus != null
        ? TransactionStatus.fromApi(tradeStatus)
        : TransactionStatus.completed;

    final signedAmount = switch (parsedSide) {
      TransactionSide.refund => rawAmount.abs(),
      _ =>
        status == TransactionStatus.reversal
            ? rawAmount.abs()
            : -(rawAmount.abs()),
    };

    return _toEntityBase(
      recordType: recordType,
      merchantName: (merchName?.isNotEmpty == true)
          ? merchName!
          : 'Unknown Merchant',
      parsedSide: parsedSide,
      signedAmount: signedAmount,
      status: status,
    );
  }

  static String? _firstNonZeroAmount(dynamic first, dynamic second) {
    for (final value in [first, second]) {
      final text = value?.toString();
      if (text == null || text.isEmpty) continue;
      final parsed = double.tryParse(text);
      if (parsed != null && parsed != 0) return text;
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
