enum UahConversionMode { rate, paidAmount }

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

  /// UAH amount as reported directly by the API (payFiatAmount / paidAmount field).
  /// Zero if the API did not provide it.
  final double paidAmountUah;

  final String currency;
  final DateTime dateTime;
  final TransactionApiStatus apiStatus;
  final TransactionTradeStatus tradeStatus;
  final TransactionSide side;
  final String? declinedReason;
  final String pan4;

  final int pointAmount;
  final String? rewardSide;
  final String? rewardType;
  final String? rewardSubType;

  final String? mccCode;
  final String? customCategory;
  final Map<String, dynamic> rawApiData;

  final UahConversionMode conversionMode;
  String get paidCurrency => rawApiData['paidCurrency']?.toString() ?? '';

  TransactionEntity({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.recordType,
    required this.amount,
    required this.paidAmount,
    this.paidAmountUah = 0.0,
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
    UahConversionMode? conversionMode,
  }) : conversionMode = conversionMode ?? UahConversionMode.rate;

  bool get hasCustomCategory =>
      customCategory != null && customCategory!.isNotEmpty;

  bool get isCardPurchase => recordType == TransactionRecordType.cardPurchase;
  bool get isBonus => recordType == TransactionRecordType.bonus;
  bool get isPurchase => isCardPurchase && amount < 0;
  bool get isRefund => isCardPurchase && amount > 0;
  double get absoluteAmount => amount.abs();

  /// Returns the absolute display amount for this transaction.
  /// When showInUah is true and conversionMode is paidAmount and the API
  /// provided a UAH value, returns that directly. Otherwise multiplies by rate.
  double effectiveDisplayAmount({
    required bool showInUah,
    required double rate,
  }) {
    if (!showInUah) return absoluteAmount;
    if (conversionMode == UahConversionMode.paidAmount &&
        paidAmountUah.abs() > 0) {
      return paidAmountUah.abs();
    }
    return absoluteAmount * rate;
  }

  int get signedPointAmount => switch (rewardSide) {
    '2' => -pointAmount.abs(),
    _ => pointAmount.abs(),
  };

  TransactionEntity copyWith({
    String? category,
    String? customCategory,
    UahConversionMode? conversionMode,
  }) {
    return TransactionEntity(
      id: id,
      merchantName: merchantName,
      category: category ?? this.category,
      recordType: recordType,
      amount: amount,
      paidAmount: paidAmount,
      paidAmountUah: paidAmountUah,
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
      conversionMode: conversionMode ?? this.conversionMode,
    );
  }
}

enum TransactionRecordType { cardPurchase, bonus }

enum TransactionApiStatus {
  init,
  pending,
  success,
  fail;

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

enum TransactionTradeStatus {
  inProgress,
  completed,
  declined,
  reversal;

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

enum TransactionSide {
  auth,
  authReversal,
  transaction,
  refundUnDeduct,
  refund,
  chargeback,
  transactionDirect,
  refundReversal,
  chargebackReversal,
  refundRequest,
  refundReversalRequest,
  chargebackFee,
  atmWithdrawal;

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
