import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://192.168.1.8:5000/api')),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final role = response.data['role'];
        final userId = response.data['_id'];
        
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_role', value: role);
        await _storage.write(key: 'user_id', value: userId);
        
        return token;
      }
      return null;
    } catch (e) {
      // In a real app, parse the error
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_id');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }
}
