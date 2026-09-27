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
typedef SessionExpiryReader = SessionExpiry Function();

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter(
    () => ref.read(sessionProvider.future),
    refreshListenable: ref.watch(routerRefreshProvider),
    readExpiry: () => ref.read(sessionExpiryProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// El aviso de sesión expirada (SCR-COM-03) se emite desde el guard: el
/// redirect es el único punto que sabe que la sesión *desapareció mientras el
/// usuario navegaba*, que es justo lo que distingue una expiración de un
/// arranque en frío. `AppSnackbar` se apoya en el `ScaffoldMessenger` raíz, así
/// que el aviso sobrevive al salto a `/login`.
void _notifySessionExpired(BuildContext context) {
  AppSnackbar.showInfo(context, 'Tu sesión ha expirado');
}

GoRouter createRouter(
  SessionReader readSession, {
  Listenable? refreshListenable,
  SessionExpiryReader? readExpiry,
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
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
        if (readExpiry?.call() == SessionExpiry.refreshFailed &&
            context.mounted) {
          _notifySessionExpired(context);
        }
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
