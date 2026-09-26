import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/auth_entities.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../catalog/presentation/home_screen.dart';
import 'splash_screen.dart';

typedef SessionReader = Future<AuthSession?> Function();

final routerProvider = Provider<GoRouter>(
  (ref) => createRouter(() => ref.read(sessionProvider.future)),
);

GoRouter createRouter(SessionReader readSession) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final session = await readSession();
      final isAuthenticated = session != null;
      final location = state.matchedLocation;

      if (location == '/') {
        return isAuthenticated ? '/home' : '/login';
      }
      if (isAuthenticated &&
          (location == '/login' || location == '/register')) {
        return '/home';
      }
      if (!isAuthenticated && location.startsWith('/home')) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShell(child: HomeScreen()),
      ),
    ],
  );
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.quickbiteOrange.withValues(alpha: 0.16),
        onDestinationSelected: (index) {
          if (index == 0) {
            return;
          }
          final label = switch (index) {
            1 => 'El carrito',
            2 => 'El historial',
            _ => 'El perfil',
          };
          AppSnackbar.showInfo(context, '$label llegará en el próximo hito.');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
