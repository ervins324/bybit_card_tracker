import 'package:bybit_card_tracker/domain/entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileEntity> syncProfile({
    required String apiKey,
    required String apiSecret,
    required String baseUrl,
  });
}
