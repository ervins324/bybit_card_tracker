import 'package:bybit_card_tracker/data/datasources/bybit_remote_datasource.dart';
import 'package:bybit_card_tracker/data/models/user_profile_model.dart';
import 'package:bybit_card_tracker/domain/entities/user_profile_entity.dart';
import 'package:bybit_card_tracker/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final BybitRemoteDataSource remoteDatasource;

  ProfileRepositoryImpl({required this.remoteDatasource});

  @override
  Future<UserProfileEntity> syncProfile({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  }) async {
    final balanceFuture = remoteDatasource.fetchFundingBalance(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    final tierFuture = remoteDatasource.fetchUserTier(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
    );

    final results = await Future.wait([balanceFuture, tierFuture]);
    final balanceJson = results[0];
    final tierJson = results[1];

    final balanceResult = (balanceJson['result'] as Map<String, dynamic>?) ?? {};
    final balanceData = (balanceResult['balance'] as Map<String, dynamic>?) ?? {};

    final tierResult = (tierJson['result'] as Map<String, dynamic>?) ?? {};

    final model = UserProfileModel(
      walletBalance: balanceData['walletBalance']?.toString(),
      transferBalance: balanceData['transferBalance']?.toString(),
      tier: tierResult['tier']?.toString(),
      limit: tierResult['limit']?.toString(),
      usedLimit: tierResult['usedLimit']?.toString(),
      unit: tierResult['unit']?.toString(),
      autoCashback: tierResult['autoCashback'] as bool?,
    );

    return model.toEntity();
  }
}
