/// Clean domain entity representing a single card transaction or bonus record.
///
/// All business logic should operate on this type, not on raw API models.
class TransactionEntity {
  final String id;
  final String merchantName;
  final String category;
  final TransactionRecordType recordType;

  /// Signed fiat amount: **negative** for purchases, **positive** for refunds.
  /// Zero for pure bonus records.
  final double amount;
  final double paidAmount;
  final String currency;
  final DateTime dateTime;
  final TransactionApiStatus apiStatus;
  final TransactionTradeStatus tradeStatus;
  final TransactionSide side;
  final String? declinedReason;
  final String pan4;

  /// Reward points for bonus records (always positive; use [rewardSide] for direction).
  final int pointAmount;
  final String? rewardSide;
  final String? rewardType;
  final String? rewardSubType;

  /// Merchant Category Code from the asset-records API.
  final String? mccCode;

  final String? customCategory;
  final Map<String, dynamic> rawApiData;

  const TransactionEntity({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.recordType,
    required this.amount,
    required this.paidAmount,
    required this.currency,
    required this.dateTime,
    required this.apiStatus,
    required this.tradeStatus,
    required this.side,
    this.declinedReason,
    required this.pan4,
    this.pointAmount = 0,
    this.rewardSide,
    this.rewardType,
    this.rewardSubType,
    this.mccCode,
    this.customCategory,
    this.rawApiData = const {},
  });

  bool get hasCustomCategory =>
      customCategory != null && customCategory!.isNotEmpty;

  bool get isCardPurchase => recordType == TransactionRecordType.cardPurchase;

  bool get isBonus => recordType == TransactionRecordType.bonus;

  /// Whether this transaction represents a purchase (money leaving the card).
  bool get isPurchase => isCardPurchase && amount < 0;

  /// Whether this transaction represents a refund (money returning).
  bool get isRefund => isCardPurchase && amount > 0;

  /// The absolute value of the fiat amount (always positive).
  double get absoluteAmount => amount.abs();

  /// Signed point delta: positive when earned, negative when spent.
  int get signedPointAmount => switch (rewardSide) {
    '2' => -pointAmount.abs(),
    _ => pointAmount.abs(),
  };

  TransactionEntity copyWith({String? category, String? customCategory}) {
    return TransactionEntity(
      id: id,
      merchantName: merchantName,
      category: category ?? this.category,
      recordType: recordType,
      amount: amount,
      paidAmount: paidAmount,
      currency: currency,
      dateTime: dateTime,
      apiStatus: apiStatus,
      tradeStatus: tradeStatus,
      side: side,
      declinedReason: declinedReason,
      pan4: pan4,
      pointAmount: pointAmount,
      rewardSide: rewardSide,
      rewardType: rewardType,
      rewardSubType: rewardSubType,
      mccCode: mccCode,
      customCategory: customCategory ?? this.customCategory,
      rawApiData: rawApiData,
    );
  }
}

enum TransactionRecordType { cardPurchase, bonus }

/// Maps the API `status` field.
enum TransactionApiStatus {
  init, // -1
  pending, // 0
  success, // 1
  fail; // 2

  static TransactionApiStatus fromApi(String? value) {
    return switch (value) {
      '-1' => TransactionApiStatus.init,
      '0' => TransactionApiStatus.pending,
      '1' => TransactionApiStatus.success,
      '2' => TransactionApiStatus.fail,
      _ => TransactionApiStatus.success,
    };
  }

  String get label => switch (this) {
    TransactionApiStatus.init => 'Init',
    TransactionApiStatus.pending => 'Pending',
    TransactionApiStatus.success => 'Success',
    TransactionApiStatus.fail => 'Fail',
  };
}

/// Maps the API `tradeStatus` field.
enum TransactionTradeStatus {
  inProgress, // 0
  completed, // 1
  declined, // 2
  reversal; // 3

  static TransactionTradeStatus fromApi(String? value) {
    return switch (value) {
      '0' => TransactionTradeStatus.inProgress,
      '1' => TransactionTradeStatus.completed,
      '2' => TransactionTradeStatus.declined,
      '3' => TransactionTradeStatus.reversal,
      _ => TransactionTradeStatus.completed,
    };
  }

  String get label => switch (this) {
    TransactionTradeStatus.inProgress => 'In Progress',
    TransactionTradeStatus.completed => 'Completed',
    TransactionTradeStatus.declined => 'Declined',
    TransactionTradeStatus.reversal => 'Reversal',
  };
}

/// Maps card transaction `side` values from the asset-records API.
enum TransactionSide {
  auth, // 1
  authReversal, // 2
  transaction, // 3
  refundUnDeduct, // 4
  refund, // 5
  chargeback, // 6
  transactionDirect, // 7
  refundReversal, // 8
  chargebackReversal, // 9
  refundRequest, // 10
  refundReversalRequest, // 11
  chargebackFee, // 12
  atmWithdrawal; // 13

  static TransactionSide fromApi(String? value) {
    return switch (value) {
      '1' => TransactionSide.auth,
      '2' => TransactionSide.authReversal,
      '3' => TransactionSide.transaction,
      '4' => TransactionSide.refundUnDeduct,
      '5' => TransactionSide.refund,
      '6' => TransactionSide.chargeback,
      '7' => TransactionSide.transactionDirect,
      '8' => TransactionSide.refundReversal,
      '9' => TransactionSide.chargebackReversal,
      '10' => TransactionSide.refundRequest,
      '11' => TransactionSide.refundReversalRequest,
      '12' => TransactionSide.chargebackFee,
      '13' => TransactionSide.atmWithdrawal,
      _ => TransactionSide.transaction,
    };
  }

  String get label => switch (this) {
    TransactionSide.auth => 'Authorization',
    TransactionSide.authReversal => 'Auth Reversal',
    TransactionSide.transaction => 'Transaction',
    TransactionSide.refundUnDeduct => 'Refund (unDeduct)',
    TransactionSide.refund => 'Refund',
    TransactionSide.chargeback => 'Chargeback',
    TransactionSide.transactionDirect => 'Transaction (Direct)',
    TransactionSide.refundReversal => 'Refund Reversal',
    TransactionSide.chargebackReversal => 'Chargeback Reversal',
    TransactionSide.refundRequest => 'Refund Request',
    TransactionSide.refundReversalRequest => 'Refund Reversal Request',
    TransactionSide.chargebackFee => 'Chargeback Fee',
    TransactionSide.atmWithdrawal => 'ATM Withdrawal',
  };
}

