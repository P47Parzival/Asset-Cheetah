import 'package:dio/dio.dart';
import 'package:data/repositories/auth_repository.dart';

class DashboardRepository {
  final Dio _dio;
  final AuthRepository _authRepository;

  DashboardRepository({required Dio dio, required AuthRepository authRepository})
      : _dio = dio,
        _authRepository = authRepository;

  Future<Map<String, dynamic>> getStats() async {
    try {
      final token = await _authRepository.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/dashboard/stats',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }
}
