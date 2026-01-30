import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:data/repositories/auth_repository.dart';
import 'package:data/repositories/dashboard_repository.dart';

// Foundation Providers (Web Safe)
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'http://localhost:5000/api', // Web defaults to localhost
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
});

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(dio: ref.watch(dioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    dio: ref.watch(dioProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});
