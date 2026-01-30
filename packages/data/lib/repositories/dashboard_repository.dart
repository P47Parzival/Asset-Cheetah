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

  Future<Map<String, dynamic>> getAssets({int page = 1, String? search}) async {
    try {
      final token = await _authRepository.getToken();
      final response = await _dio.get(
        '/assets',
        queryParameters: {
          'page': page,
          if (search != null) 'search': search,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch assets: $e');
    }
  }

  Future<Map<String, dynamic>> getAsset(String id) async {
    try {
      final token = await _authRepository.getToken();
      final response = await _dio.get(
        '/assets/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch asset: $e');
    }
  }

  Future<List<dynamic>> getAssetEvents(String id) async {
    try {
      final token = await _authRepository.getToken();
      final response = await _dio.get(
        '/assets/$id/events',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch asset events: $e');
    }
  }

  Future<void> createAsset(Map<String, dynamic> data) async {
    try {
      final token = await _authRepository.getToken();
      await _dio.post(
        '/assets',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to create asset: $e');
    }
  }
}
