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
  final String currency;
  final DateTime dateTime;
  final TransactionStatus status;
  final TransactionSide side;
  final String? declinedReason;
  final String pan4;

  /// Reward points for bonus records (always positive; use [rewardSide] for direction).
  final int pointAmount;
  final String? rewardSide;
  final String? rewardType;
  final String? rewardSubType;
  final String? customCategory;
  final Map<String, dynamic> rawApiData;

  const TransactionEntity({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.recordType,
    required this.amount,
    required this.currency,
    required this.dateTime,
    required this.status,
    required this.side,
    this.declinedReason,
    required this.pan4,
    this.pointAmount = 0,
    this.rewardSide,
    this.rewardType,
    this.rewardSubType,
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
      currency: currency,
      dateTime: dateTime,
      status: status,
      side: side,
      declinedReason: declinedReason,
      pan4: pan4,
      pointAmount: pointAmount,
      rewardSide: rewardSide,
      rewardType: rewardType,
      rewardSubType: rewardSubType,
      customCategory: customCategory ?? this.customCategory,
      rawApiData: rawApiData,
    );
  }
}

enum TransactionRecordType { cardPurchase, bonus }

/// Maps the API `tradeStatus` field.
enum TransactionStatus {
  inProgress, // 0
  completed, // 1
  declined, // 2
  reversal; // 3

  static TransactionStatus fromApi(String? value) {
    return switch (value) {
      '0' => TransactionStatus.inProgress,
      '1' => TransactionStatus.completed,
      '2' => TransactionStatus.declined,
      '3' => TransactionStatus.reversal,
      _ => TransactionStatus.inProgress,
    };
  }

  String get label => switch (this) {
        TransactionStatus.inProgress => 'In Progress',
        TransactionStatus.completed => 'Completed',
        TransactionStatus.declined => 'Declined',
        TransactionStatus.reversal => 'Reversal',
      };
}

/// Maps card transaction `side` values from the asset-records API.
enum TransactionSide {
  auth, // 1
  transaction, // 3
  refund, // 5
  atmWithdrawal; // 13

  static TransactionSide fromApi(String? value) {
    return switch (value) {
      '1' => TransactionSide.auth,
      '3' => TransactionSide.transaction,
      '5' => TransactionSide.refund,
      '13' => TransactionSide.atmWithdrawal,
      _ => TransactionSide.transaction,
    };
  }

  String get label => switch (this) {
        TransactionSide.auth => 'Authorization',
        TransactionSide.transaction => 'Purchase',
        TransactionSide.refund => 'Refund',
        TransactionSide.atmWithdrawal => 'ATM Withdrawal',
      };
}
