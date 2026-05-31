import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/users_service.dart';
import 'auth_provider.dart';

final usersServiceProvider = Provider<UsersService>(
  (ref) => UsersService(ref.watch(apiClientProvider)),
);

final allUsersProvider = FutureProvider<List<User>>((ref) {
  return ref.watch(usersServiceProvider).getAll();
});

final teachersProvider = FutureProvider<List<User>>((ref) {
  return ref.watch(usersServiceProvider).getTeachers();
});
