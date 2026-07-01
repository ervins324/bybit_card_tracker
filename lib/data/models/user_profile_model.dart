import 'package:bybit_card_tracker/domain/entities/user_profile_entity.dart';

class UserProfileModel {
  final String? walletBalance;
  final String? transferBalance;
  final String? tier;
  final String? limit;
  final String? usedLimit;
  final String? unit;
  final bool? autoCashback;

  const UserProfileModel({
    this.walletBalance,
    this.transferBalance,
    this.tier,
    this.limit,
    this.usedLimit,
    this.unit,
    this.autoCashback,
  });

  UserProfileEntity toEntity() {
    return UserProfileEntity(
      usdtWalletBalance: double.tryParse(walletBalance ?? '0') ?? 0.0,
      usdtTransferBalance: double.tryParse(transferBalance ?? '0') ?? 0.0,
      tier: tier ?? 'Unknown',
      limit: double.tryParse(limit ?? '0') ?? 0.0,
      usedLimit: double.tryParse(usedLimit ?? '0') ?? 0.0,
      unit: unit ?? '',
      autoCashback: autoCashback ?? false,
    );
  }
}
