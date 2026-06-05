/// Labels and classification for Bybit reward point records.
class BonusTypes {
  BonusTypes._();

  /// Rewards Hub redemption (not a card purchase).
  static bool isRewardsHub({String? rewardType, String? rewardSubType}) =>
      rewardType == '5' && rewardSubType == '3';

  /// Merchant refund — points clawed back (type 1 / subType 2).
  static bool isRefund({
    required String? rewardType,
    required String? rewardSubType,
  }) =>
      rewardType == '1' && rewardSubType == '2';

  /// Card purchase with cashback (type 1 / subType 1, points earned).
  static bool isPurchase({
    required String? rewardType,
    required String? rewardSubType,
  }) =>
      rewardType == '1' && (rewardSubType == '1' || rewardSubType == null);

  /// Whether this reward record represents a real card spend or refund.
  static bool isCardTransaction({
    required String? rewardType,
    required String? rewardSubType,
    required String? merchName,
    required double spendAmount,
  }) {
    if (isRewardsHub(rewardType: rewardType, rewardSubType: rewardSubType)) {
      return false;
    }
    final hasMerchant = merchName?.trim().isNotEmpty ?? false;
    if (!hasMerchant || spendAmount <= 0) return false;

    if (isRefund(rewardType: rewardType, rewardSubType: rewardSubType)) {
      return true;
    }
    if (isPurchase(rewardType: rewardType, rewardSubType: rewardSubType)) {
      return true;
    }
    if (rewardType?.toUpperCase() == 'CASHBACK') return true;
    if (rewardType == '1') return true;
    return rewardType == null && rewardSubType == null;
  }

  /// Human-readable label for a reward point record.
  static String describe({
    required String? rewardType,
    required String? rewardSubType,
    required String? rewardSide,
    String? merchName,
  }) {
    if (isRewardsHub(rewardType: rewardType, rewardSubType: rewardSubType)) {
      return 'Rewards Hub';
    }

    if (isRefund(rewardType: rewardType, rewardSubType: rewardSubType)) {
      if (merchName?.trim().isNotEmpty == true) {
        return '${merchName!.trim()} (Refund)';
      }
      return 'Refund';
    }

    final typeLabel = switch (rewardType?.toUpperCase()) {
      'CASHBACK' => 'Cashback',
      '5' => 'Rewards Hub',
      _ => rewardType?.isNotEmpty == true ? rewardType! : null,
    };

    if (typeLabel != null) return typeLabel;

    if (merchName?.trim().isNotEmpty == true) {
      return merchName!.trim();
    }

    return switch (rewardSide) {
      '1' => 'Points earned',
      '2' => 'Points spent',
      _ => 'Bonus activity',
    };
  }

  static String sideLabel(String? rewardSide) => switch (rewardSide) {
        '1' => 'Earned',
        '2' => 'Spent',
        _ => 'Bonus',
      };
}
