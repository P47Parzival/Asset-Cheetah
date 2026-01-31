import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/web_providers.dart';
import 'package:dio/dio.dart';

// Provider to fetch and cache user role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  // The role is stored during login. We can retrieve it from secure storage.
  // For simplicity, we'll add a getRole method to AuthRepository.
  // For now, let's assume it's stored and retrieve it.
  try {
    final dio = ref.watch(dioProvider);
    final token = await authRepo.getToken();
    if (token == null) return null;
    
    // Decode role from JWT or fetch from API
    // Simple approach: fetch user profile
    final response = await dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['role'] as String?;
  } catch (e) {
    return null;
  }
});

// Simple sync provider for immediate access (after login)
final currentUserRoleProvider = StateProvider<String?>((ref) => null);
