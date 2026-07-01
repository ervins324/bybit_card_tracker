import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:bybit_card_tracker/data/datasources/bybit_remote_datasource.dart';
import 'package:bybit_card_tracker/data/repositories/profile_repository_impl.dart';
import 'package:bybit_card_tracker/domain/entities/user_profile_entity.dart';
import 'package:bybit_card_tracker/domain/repositories/profile_repository.dart';
import 'package:bybit_card_tracker/presentation/providers/credentials_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDatasource = BybitRemoteDataSourceImpl(client: http.Client());
  return ProfileRepositoryImpl(remoteDatasource: remoteDatasource);
});

final profileProvider = FutureProvider<UserProfileEntity>((ref) async {
  final credentials = ref.watch(credentialsProvider).valueOrNull;
  if (credentials == null || !credentials.isValid) {
    throw Exception('API credentials not configured.');
  }

  final repo = ref.watch(profileRepositoryProvider);
  return repo.syncProfile(
    apiKey: credentials.apiKey,
    apiSecret: credentials.apiSecret,
    baseUrl: credentials.baseUrl,
  );
});
