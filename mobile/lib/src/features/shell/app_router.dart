import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../address/presentation/address_form_screen.dart';
import '../address/presentation/addresses_screen.dart';
import '../auth/domain/auth_entities.dart';
import '../search/presentation/search_screen.dart';
import '../auth/presentation/auth_providers.dart';
import '../auth/presentation/edit_profile_screen.dart';
import '../auth/presentation/forgot_password_screen.dart';
import '../auth/presentation/login_screen.dart';
import '../auth/presentation/profile_screen.dart';
import '../auth/presentation/register_screen.dart';
import '../auth/presentation/reset_password_screen.dart';
import '../cart/presentation/cart_screen.dart';
import '../catalog/presentation/home_screen.dart';
import '../catalog/presentation/product_detail_screen.dart';
import '../order/presentation/checkout_screen.dart';
import '../order/presentation/order_confirmation_screen.dart';
import '../notification/presentation/notification_preferences_screen.dart';
import '../notification/presentation/notifications_screen.dart';
import '../order/presentation/order_detail_screen.dart';
import '../order/presentation/orders_screen.dart';
import '../profile/presentation/appearance_screen.dart';
import '../profile/presentation/about_screen.dart';
import '../profile/presentation/advanced_screen.dart';
import '../profile/presentation/delete_account_screen.dart';
import '../profile/presentation/help_screen.dart';
import '../profile/presentation/privacy_screen.dart';
import '../profile/presentation/change_password_screen.dart';
import '../profile/presentation/language_screen.dart';
import '../profile/presentation/security_screen.dart';
import '../profile/presentation/sessions_screen.dart';
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

const _publicRoutes = {
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
};

const _clienteOnlyExact = {
  '/cart',
  '/checkout',
  '/history',
  '/addresses',
  '/addresses/new',
  '/search',
};
const _clienteOnlyPrefixes = ['/home', '/product/', '/order/', '/addresses/'];

/// Pantalla de inicio de cada rol (07 §10.3). Un usuario sin sesión va a
/// `/login`; con sesión, la ruta la decide la entidad para que el login y el
/// guard no puedan discrepar.
String homeFor(AuthSession? session) {
  if (session == null) {
    return '/login';
  }
  return session.user.homePath;
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

      if (session != null && _publicRoutes.contains(location)) {
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
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
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
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) => const SecurityScreen(),
                    routes: [
                      // El subhub de 07.1 es el padre de sus dos secciones: al
                      // abrir cualquiera de ellas queda debajo, así que volver
                      // con el gesto del sistema regresa a Seguridad.
                      GoRoute(
                        path: 'password',
                        builder: (context, state) =>
                            const ChangePasswordScreen(),
                      ),
                      GoRoute(
                        path: 'sessions',
                        builder: (context, state) => const SessionsScreen(),
                      ),
                    ],
                  ),
                  // 07 §10.2 lista las sesiones como ruta plana y 07.1 las
                  // anida bajo Seguridad. Ambas resuelven a la misma pantalla.
                  GoRoute(
                    path: 'sessions',
                    builder: (context, state) => const SessionsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationPreferencesScreen(),
                  ),
                  GoRoute(
                    path: 'appearance',
                    builder: (context, state) => const AppearanceScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyScreen(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const HelpScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                  GoRoute(
                    path: 'advanced',
                    builder: (context, state) => const AdvancedScreen(),
                  ),
                  GoRoute(
                    path: 'language',
                    builder: (context, state) => const LanguageScreen(),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    builder: (context, state) => const DeleteAccountScreen(),
                  ),
                  // `/profile/account` fue el nombre con el que se enlazaba
                  // "Eliminar cuenta" en las maquetas: se conserva y redirige
                  // a la ruta buena.
                  GoRoute(
                    path: 'account',
                    redirect: (context, state) => '/profile/delete-account',
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
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order/confirmation/:id',
        builder: (context, state) =>
            OrderConfirmationScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const AddressFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                AddressFormScreen(addressId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
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
