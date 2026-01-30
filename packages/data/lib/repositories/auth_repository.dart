import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://192.168.1.8:5000/api')),
        _storage = storage ?? const FlutterSecureStorage();

  final Map<String, String> _memoryStorage = {};

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('SecureStorage Write Error (Using Memory Fallback): $e');
      _memoryStorage[key] = value;
    }
  }

  Future<String?> _safeRead(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value ?? _memoryStorage[key]; // If secure storage returns null (or throws), try memory
    } catch (e) {
      print('SecureStorage Read Error (Using Memory Fallback): $e');
      return _memoryStorage[key];
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('SecureStorage Delete Error: $e');
    }
    _memoryStorage.remove(key);
  }

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
        
        await _safeWrite('jwt_token', token);
        await _safeWrite('user_role', role);
        await _safeWrite('user_id', userId);
        
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
    await _safeDelete('jwt_token');
    await _safeDelete('user_role');
    await _safeDelete('user_id');
  }

  Future<String?> getToken() async {
    return await _safeRead('jwt_token');
  }

  Future<String?> getUserId() async {
    return await _safeRead('user_id');
  }
}
