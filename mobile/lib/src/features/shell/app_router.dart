import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../auth/domain/auth_entities.dart';
import '../auth/presentation/auth_providers.dart';
import '../auth/presentation/login_screen.dart';
import '../auth/presentation/register_screen.dart';
import '../catalog/presentation/home_screen.dart';
import 'pending_screen.dart';
import 'splash_screen.dart';

typedef SessionReader = Future<AuthSession?> Function();
typedef SessionExpiryReader = SessionExpiry Function();

/// Índices de rama de `StatefulShellRoute`. Las cuatro primeras son las
/// pestañas del cliente y las tres siguientes las del repartidor (07 §10.4);
/// el orden es fijo porque el shell lo usa para traducir el índice visible de
/// la barra al índice real de rama.
abstract final class ShellBranch {
  static const clienteCatalogo = 0;
  static const clienteCarrito = 1;
  static const clienteHistorial = 2;
  static const clientePerfil = 3;
  static const repartidorDisponibles = 4;
  static const repartidorActiva = 5;
  static const repartidorHistorial = 6;
}

class ShellTab {
  const ShellTab({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const clienteTabs = <ShellTab>[
  ShellTab(
    branchIndex: ShellBranch.clienteCatalogo,
    label: 'Catálogo',
    icon: Icons.restaurant_menu_outlined,
    selectedIcon: Icons.restaurant_menu,
  ),
  ShellTab(
    branchIndex: ShellBranch.clienteCarrito,
    label: 'Carrito',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
  ),
  ShellTab(
    branchIndex: ShellBranch.clienteHistorial,
    label: 'Historial',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  ShellTab(
    branchIndex: ShellBranch.clientePerfil,
    label: 'Perfil',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

const repartidorTabs = <ShellTab>[
  ShellTab(
    branchIndex: ShellBranch.repartidorDisponibles,
    label: 'Disponibles',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping,
  ),
  ShellTab(
    branchIndex: ShellBranch.repartidorActiva,
    label: 'Entrega activa',
    icon: Icons.pedal_bike_outlined,
    selectedIcon: Icons.pedal_bike,
  ),
  ShellTab(
    branchIndex: ShellBranch.repartidorHistorial,
    label: 'Historial',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
];

/// Pestañas que corresponden a un rol (07 §10.4).
List<ShellTab> shellTabsFor(String rol) =>
    rol == 'repartidor' ? repartidorTabs : clienteTabs;

const _publicRoutes = {'/', '/login', '/register', '/forgot-password'};

const _clienteOnlyExact = {'/cart', '/checkout', '/history', '/addresses'};
const _clienteOnlyPrefixes = ['/home', '/product/', '/order/'];

/// Pantalla de inicio de cada rol (07 §10.3). Un usuario sin sesión va a
/// `/login`; cualquier rol que no sea repartidor se trata como cliente, porque
/// el administrador no tiene superficie propia en la app móvil.
String homeFor(AuthSession? session) {
  if (session == null) {
    return '/login';
  }
  return session.user.isRepartidor ? '/delivery/available' : '/home';
}

bool _isClienteOnly(String location) =>
    _clienteOnlyExact.contains(location) ||
    _clienteOnlyPrefixes.any(location.startsWith);

/// ¿El rol tiene acceso a la ruta? Las rutas de repartidor y las de cliente no
/// se cruzan; el resto solo exige sesión.
bool roleAllows(String rol, String location) {
  if (location.startsWith('/delivery/')) {
    return rol == 'repartidor';
  }
  if (_isClienteOnly(location)) {
    return rol == 'cliente';
  }
  return true;
}

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
      final location = state.matchedLocation;
      final home = homeFor(session);

      if (location == '/') {
        return home;
      }

      if (!_publicRoutes.contains(location)) {
        if (session == null) {
          if (readExpiry?.call() == SessionExpiry.refreshFailed &&
              context.mounted) {
            _notifySessionExpired(context);
          }
          return '/login';
        }
        if (!roleAllows(session.user.rol, location)) {
          return home;
        }
      }

      if (session != null &&
          (location == '/login' || location == '/register')) {
        return home;
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
        path: '/forgot-password',
        builder: (context, state) => const PendingScreen(
          location: '/forgot-password',
          title: 'Recuperar contraseña',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Cliente
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) =>
                    const PendingScreen(location: '/cart', title: 'Carrito'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const PendingScreen(
                  location: '/history',
                  title: 'Historial de pedidos',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const PendingScreen(location: '/profile', title: 'Perfil'),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/edit',
                      title: 'Editar perfil',
                    ),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/security',
                      title: 'Seguridad',
                    ),
                  ),
                  GoRoute(
                    path: 'sessions',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/sessions',
                      title: 'Sesiones activas',
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/notifications',
                      title: 'Preferencias de notificaciones',
                    ),
                  ),
                  GoRoute(
                    path: 'appearance',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/appearance',
                      title: 'Apariencia',
                    ),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/privacy',
                      title: 'Privacidad',
                    ),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/help',
                      title: 'Ayuda',
                    ),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/about',
                      title: 'Acerca de',
                    ),
                  ),
                  GoRoute(
                    path: 'advanced',
                    builder: (context, state) => const PendingScreen(
                      location: '/profile/advanced',
                      title: 'Avanzado',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Repartidor
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/available',
                builder: (context, state) => const PendingScreen(
                  location: '/delivery/available',
                  title: 'Pedidos disponibles',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/active',
                builder: (context, state) => const PendingScreen(
                  location: '/delivery/active',
                  title: 'Entrega activa',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/history',
                builder: (context, state) => const PendingScreen(
                  location: '/delivery/history',
                  title: 'Historial de entregas',
                ),
              ),
            ],
          ),
        ],
      ),
      // Rutas de detalle y tarea. Al declararse en el nivel raíz se abren
      // sobre el shell, a pantalla completa y sin barra de pestañas.
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => PendingScreen(
          location: state.uri.path,
          title: 'Detalle de producto',
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const PendingScreen(
          location: '/checkout',
          title: 'Confirmación de pedido',
        ),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) => PendingScreen(
          location: state.uri.path,
          title: 'Seguimiento del pedido',
        ),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) =>
            const PendingScreen(location: '/addresses', title: 'Direcciones'),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const PendingScreen(
          location: '/notifications',
          title: 'Notificaciones',
        ),
      ),
      GoRoute(
        path: '/delivery/stats',
        builder: (context, state) => const PendingScreen(
          location: '/delivery/stats',
          title: 'Estadísticas',
        ),
      ),
    ],
  );
}

/// Shell con pestañas. `StatefulNavigationShell` conserva el estado de cada
/// rama, y el índice seleccionado se deriva de la rama activa en lugar de
/// estar fijado en el primer destino.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(sessionProvider).value?.user.rol ?? 'cliente';
    final tabs = shellTabsFor(rol);
    final selected = tabs.indexWhere(
      (tab) => tab.branchIndex == navigationShell.currentIndex,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.quickbiteOrange.withValues(alpha: 0.16),
        onDestinationSelected: (index) => navigationShell.goBranch(
          tabs[index].branchIndex,
          initialLocation: index == 0,
        ),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
