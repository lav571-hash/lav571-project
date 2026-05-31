import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  final _storage = const FlutterSecureStorage();

  AuthService(this._client);

  Future<AuthResponse> register({
    required String email,
    required String fullName,
    required String password,
    String? phone,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'fullName': fullName,
      'password': password,
      if (phone != null) 'phone': phone,
    });
    final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(auth);
    return auth;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(auth);
    return auth;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _client.get('/users/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTokens(AuthResponse auth) async {
    await _storage.write(key: 'access_token', value: auth.accessToken);
    await _storage.write(key: 'refresh_token', value: auth.refreshToken);
  }
}
