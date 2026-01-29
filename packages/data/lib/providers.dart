import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/services/local_database.dart';
import 'package:data/repositories/auth_repository.dart';
import 'package:data/repositories/sync_repository.dart';
import 'package:dio/dio.dart';

// Foundation Providers
final dioProvider = Provider<Dio>((ref) {
  // In real app, add interceptors for auth token here
  return Dio(BaseOptions(
    baseUrl: 'http://localhost:5000/api', // Use 10.0.2.2 for Android Emulator
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
});

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(dio: ref.watch(dioProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    dio: ref.watch(dioProvider),
    localDb: ref.watch(localDatabaseProvider),
  );
});
