class UserProfileEntity {
  final double usdtWalletBalance;
  final double usdtTransferBalance;
  final String tier;
  final double limit;
  final double usedLimit;
  final String unit;
  final bool autoCashback;

  const UserProfileEntity({
    required this.usdtWalletBalance,
    required this.usdtTransferBalance,
    required this.tier,
    required this.limit,
    required this.usedLimit,
    required this.unit,
    required this.autoCashback,
  });

  static const _tierNames = {
    'REWARDS_LIMITS_TIER1': 'Base (2%)',
    'REWARDS_LIMITS_TIER2': 'Beta (2%)',
    'REWARDS_LIMITS_TIER3': 'Alpha (4%)',
    'REWARDS_LIMITS_TIER4': 'Apex (6%)',
    'REWARDS_LIMITS_TIER5': 'Omega (8%)',
    'REWARDS_LIMITS_TIER6': 'Infinite (10%)',
  };

  String get tierDisplayName {
    final upper = tier.toUpperCase();
    return _tierNames[upper] ?? upper;
  }
}
