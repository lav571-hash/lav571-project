import '../models/user.dart';
import 'api_client.dart';

class UsersService {
  final ApiClient _client;

  UsersService(this._client);

  Future<List<User>> getAll({String? role}) async {
    final response = await _client.get('/users', params: {
      if (role != null) 'role': role,
    });
    final list = response.data as List<dynamic>;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User> createUser({
    required String email,
    required String fullName,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final response = await _client.post('/users', data: {
      'email': email,
      'fullName': fullName,
      'password': password,
      'role': role == UserRole.admin ? 'admin' : 'teacher',
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deactivate(String id) async {
    await _client.delete('/users/$id');
  }

  Future<List<User>> getTeachers() async {
    final response = await _client.get('/users/teachers');
    final list = response.data as List<dynamic>;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }
}
