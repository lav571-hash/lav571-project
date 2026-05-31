import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../services/courses_service.dart';
import 'auth_provider.dart';

final coursesServiceProvider = Provider<CoursesService>(
  (ref) => CoursesService(ref.watch(apiClientProvider)),
);

final publishedCoursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(coursesServiceProvider).getPublishedCourses();
});

final allCoursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(coursesServiceProvider).getAllCourses();
});

final courseDetailProvider =
    FutureProvider.family<Course, String>((ref, id) {
  return ref.watch(coursesServiceProvider).getCourse(id);
});

final courseSeatsProvider =
    FutureProvider.family<int, String>((ref, courseId) {
  return ref.watch(coursesServiceProvider).getAvailableSeats(courseId);
});
