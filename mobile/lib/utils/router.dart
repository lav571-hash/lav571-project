import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/course_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/admin/create_course_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authAsync.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/home') {
        return '/login';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const CatalogScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (_, state) => CourseDetailScreen(
          courseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/courses/create',
        builder: (_, __) => const CreateCourseScreen(),
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final userAsync = ref.watch(authProvider);
    final user = userAsync.valueOrNull;

    int currentIndex = 0;
    if (location == '/home') currentIndex = 0;
    if (location == '/profile') currentIndex = 1;
    if (location == '/admin') currentIndex = 2;

    final showAdmin = user != null &&
        (user.role.name == 'admin' || user.role.name == 'teacher');

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, showAdmin ? 2 : 1),
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/profile');
            case 2:
              if (showAdmin) context.go('/admin');
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Курсы',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
          if (showAdmin)
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              activeIcon: const Icon(Icons.admin_panel_settings),
              label: user.role.name == 'admin' ? 'Админ' : 'Учитель',
            ),
        ],
      ),
    );
  }
}
