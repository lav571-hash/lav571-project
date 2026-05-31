import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final service = ref.read(authServiceProvider);
    final loggedIn = await service.isLoggedIn();
    if (!loggedIn) return null;
    return service.getCurrentUser();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final service = ref.read(authServiceProvider);
    final auth = await service.login(email: email, password: password);
    state = AsyncData(auth.user);
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    String? phone,
  }) async {
    state = const AsyncLoading();
    final service = ref.read(authServiceProvider);
    final auth = await service.register(
      email: email,
      fullName: fullName,
      password: password,
      phone: phone,
    );
    state = AsyncData(auth.user);
  }

  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.logout();
    state = const AsyncData(null);
  }

  Future<void> refresh() async {
    final service = ref.read(authServiceProvider);
    final user = await service.getCurrentUser();
    state = AsyncData(user);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
