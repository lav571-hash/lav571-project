import '../models/course.dart';
import 'api_client.dart';

class CoursesService {
  final ApiClient _client;

  CoursesService(this._client);

  Future<List<Course>> getPublishedCourses() async {
    final response = await _client.get('/courses/published');
    final list = response.data as List<dynamic>;
    return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Course>> getAllCourses({
    String? level,
    String? type,
    String? status,
  }) async {
    final response = await _client.get('/courses', params: {
      if (level != null) 'level': level,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    });
    final list = response.data as List<dynamic>;
    return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Course> getCourse(String id) async {
    final response = await _client.get('/courses/$id');
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> getAvailableSeats(String courseId) async {
    final response = await _client.get('/courses/$courseId/seats');
    return (response.data as Map<String, dynamic>)['seats'] as int;
  }

  Future<List<Session>> getSessions(String courseId) async {
    final response = await _client.get('/courses/$courseId/sessions');
    final list = response.data as List<dynamic>;
    return list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Material>> getMaterials(String courseId) async {
    final response = await _client.get('/courses/$courseId/materials');
    final list = response.data as List<dynamic>;
    return list.map((e) => Material.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    final response = await _client.post('/courses', data: data);
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Course> updateCourse(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/courses/$id', data: data);
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Course> publishCourse(String id) async {
    final response = await _client.patch('/courses/$id/publish');
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Session> addSession(String courseId, Map<String, dynamic> data) async {
    final response = await _client.post('/courses/$courseId/sessions', data: data);
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Material> addMaterial(String courseId, Map<String, dynamic> data) async {
    final response = await _client.post('/courses/$courseId/materials', data: data);
    return Material.fromJson(response.data as Map<String, dynamic>);
  }
}
