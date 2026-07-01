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
}
