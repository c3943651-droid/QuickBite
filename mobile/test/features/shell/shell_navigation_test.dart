import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';

import '../../support/router_harness.dart';

void main() {
  final cliente = sessionFor('cliente');
  final repartidor = sessionFor('repartidor');

  group('pestañas del cliente (07 §10.4)', () {
    testWidgets(
      'muestra cuatro destinos: catálogo, carrito, historial y perfil',
      (tester) async {
        await pumpRouter(tester, cliente);

        expect(find.text('Catálogo'), findsOneWidget);
        expect(find.text('Carrito'), findsOneWidget);
        expect(find.text('Historial'), findsOneWidget);
        expect(find.text('Perfil'), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(4));
      },
    );

    testWidgets('cada pestaña navega a su ruta', (tester) async {
      final router = await pumpRouter(tester, cliente);

      await tester.tap(find.text('Carrito'));
      await settle(tester);
      expect(locationOf(router), '/cart');

      await tester.tap(find.text('Historial'));
      await settle(tester);
      expect(locationOf(router), '/history');

      await tester.tap(find.text('Perfil'));
      await settle(tester);
      expect(locationOf(router), '/profile');
    });

    testWidgets(
      'la pestaña seleccionada se deriva de la ruta, no está fijada',
      (tester) async {
        final router = await pumpRouter(tester, cliente);

        router.go('/profile');
        await settle(tester);

        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.selectedIndex, 3);
        expect(locationOf(router), '/profile');
      },
    );

    testWidgets('cada pestaña conserva su estado al alternar', (tester) async {
      final router = await pumpRouter(tester, cliente);

      await tester.enterText(find.byType(TextField).first, 'pizza');
      await settle(tester);

      await tester.tap(find.text('Carrito'));
      await settle(tester);
      expect(locationOf(router), '/cart');

      await tester.tap(find.text('Catálogo'));
      await settle(tester);

      expect(find.text('pizza'), findsOneWidget);
    });
  });

  group('pestañas del repartidor (07 §10.4)', () {
    testWidgets(
      'muestra tres destinos: disponibles, entrega activa e historial',
      (tester) async {
        await pumpRouter(tester, repartidor);

        expect(find.text('Disponibles'), findsOneWidget);
        expect(find.text('Entrega activa'), findsOneWidget);
        expect(find.text('Historial'), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(find.text('Carrito'), findsNothing);
        expect(find.text('Catálogo'), findsNothing);
      },
    );

    testWidgets('cada pestaña navega a su ruta', (tester) async {
      final router = await pumpRouter(tester, repartidor);

      await tester.tap(find.text('Entrega activa'));
      await settle(tester);
      expect(locationOf(router), '/delivery/active');

      await tester.tap(find.text('Historial'));
      await settle(tester);
      expect(locationOf(router), '/delivery/history');
    });

    testWidgets('la ruta de arranque es pedidos disponibles', (tester) async {
      final router = await pumpRouter(tester, repartidor);

      expect(locationOf(router), '/delivery/available');
    });
  });

  group('guardas por rol (07 §10.3)', () {
    testWidgets(
      'el repartidor que entra a una ruta de cliente vuelve a su inicio',
      (tester) async {
        final router = await pumpRouter(tester, repartidor);

        router.go('/cart');
        await settle(tester);
        expect(locationOf(router), '/delivery/available');

        router.go('/home');
        await settle(tester);
        expect(locationOf(router), '/delivery/available');
      },
    );

    testWidgets(
      'el cliente que entra a una ruta de repartidor vuelve a su inicio',
      (tester) async {
        final router = await pumpRouter(tester, cliente);

        router.go('/delivery/available');
        await settle(tester);
        expect(locationOf(router), '/home');
      },
    );

    testWidgets('sin sesión, toda ruta autenticada redirige a /login', (
      tester,
    ) async {
      final router = await pumpRouter(tester, null);

      for (final path in [
        '/cart',
        '/checkout',
        '/history',
        '/profile',
        '/addresses',
        '/search',
        '/notifications',
        '/delivery/available',
        '/delivery/stats',
      ]) {
        router.go(path);
        await settle(tester);
        expect(locationOf(router), '/login', reason: 'ruta $path');
      }
    });

    testWidgets('sin sesión, las rutas públicas siguen accesibles', (
      tester,
    ) async {
      final router = await pumpRouter(tester, null);

      router.go('/register');
      await settle(tester);
      expect(locationOf(router), '/register');

      router.go('/forgot-password');
      await settle(tester);
      expect(locationOf(router), '/forgot-password');
    });

    testWidgets(
      'autenticado, /login devuelve a la pantalla principal del rol',
      (tester) async {
        var router = await pumpRouter(tester, cliente);
        expect(locationOf(router), '/home');

        router = await pumpRouter(tester, repartidor);
        expect(locationOf(router), '/delivery/available');
      },
    );

    testWidgets('el perfil es accesible para ambos roles', (tester) async {
      var router = await pumpRouter(tester, cliente);
      router.go('/profile');
      await settle(tester);
      expect(locationOf(router), '/profile');

      router = await pumpRouter(tester, repartidor);
      router.go('/profile');
      await settle(tester);
      expect(locationOf(router), '/profile');
    });
  });

  group('las 27 rutas de 07 §10.2', () {
    const clienteRoutes = [
      '/product/7',
      '/cart',
      '/checkout',
      '/order/confirmation/9',
      '/order/9',
      '/history',
      '/addresses',
      '/search',
    ];
    const anyAuthenticated = [
      '/profile',
      '/profile/edit',
      '/profile/security',
      '/profile/security/password',
      '/profile/security/sessions',
      '/profile/sessions',
      '/profile/notifications',
      '/profile/appearance',
      '/profile/language',
      '/profile/privacy',
      '/profile/help',
      '/profile/about',
      '/profile/advanced',
      '/profile/delete-account',
      '/notifications',
    ];
    const repartidorRoutes = [
      '/delivery/available',
      '/delivery/active',
      '/delivery/history',
      '/delivery/stats',
    ];
    const publicRoutes = [
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
    ];
    const realScreens = {
      '/home',
      '/cart',
      '/checkout',
      '/order/confirmation/9',
      '/order/9',
      '/history',
      '/notifications',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
      '/profile',
      '/profile/edit',
      '/profile/notifications',
      '/profile/appearance',
      '/profile/language',
      '/profile/privacy',
      '/profile/help',
      '/profile/about',
      '/profile/advanced',
      '/profile/delete-account',
      '/profile/security',
      '/profile/security/password',
      '/profile/security/sessions',
      '/profile/sessions',
      '/addresses',
      '/search',
      '/product/7',
    };

    Future<void> expectResolves(
      WidgetTester tester,
      AuthSession? session,
      String path,
    ) async {
      final router = await pumpRouter(tester, session);
      router.go(path);
      await settle(tester);

      expect(locationOf(router), path, reason: 'la ruta $path debe resolverse');
      if (!realScreens.contains(path)) {
        expect(pendingAt(path), findsOneWidget, reason: 'falta $path');
      }
    }

    testWidgets(
      'las pantallas de ajustes ya no son marcadores de posición',
      (tester) async {
        for (final entrada in {
          '/profile/appearance': 'Apariencia',
          '/profile/language': 'Idioma y región',
          '/profile/privacy': 'Privacidad',
          '/profile/help': 'Ayuda y soporte',
          '/profile/about': 'Acerca de',
          '/profile/advanced': 'Avanzado',
          '/profile/delete-account': 'Eliminar cuenta',
        }.entries) {
          final router = await pumpRouter(tester, cliente);
          router.go(entrada.key);
          await settle(tester);

          expect(
            pendingAt(entrada.key),
            findsNothing,
            reason: '${entrada.key} ya tiene pantalla propia',
          );
          expect(
            find.widgetWithText(AppBar, entrada.value),
            findsOneWidget,
            reason: '${entrada.key} debe abrir ${entrada.value}',
          );
        }
      },
    );

    testWidgets('/profile/account redirige a la pantalla de eliminar cuenta', (
      tester,
    ) async {
      final router = await pumpRouter(tester, cliente);
      router.go('/profile/account');
      await settle(tester);

      expect(locationOf(router), '/profile/delete-account');
      expect(pendingAt('/profile/account'), findsNothing);
    });

    testWidgets('rutas públicas', (tester) async {
      for (final path in publicRoutes) {
        await expectResolves(tester, null, path);
      }
    });

    testWidgets('rutas de cliente', (tester) async {
      for (final path in clienteRoutes) {
        await expectResolves(tester, cliente, path);
      }
    });

    testWidgets('el formulario de dirección resuelve en nueva y edición', (
      tester,
    ) async {
      for (final entry in {
        '/addresses/new': 'Agregar dirección',
        '/addresses/22222222-2222-2222-2222-222222222222/edit':
            'Editar dirección',
      }.entries) {
        final router = await pumpRouter(tester, cliente);
        router.go(entry.key);
        await settle(tester);

        expect(
          locationOf(router),
          entry.key,
          reason: 'la ruta ${entry.key} debe resolverse',
        );
        expect(
          find.widgetWithText(AppBar, entry.value),
          findsOneWidget,
          reason: 'falta el encabezado de ${entry.key}',
        );
      }
    });

    testWidgets('un repartidor no entra a las rutas de direcciones', (
      tester,
    ) async {
      final router = await pumpRouter(tester, repartidor);
      for (final path in [
        '/addresses',
        '/addresses/new',
        '/addresses/22222222-2222-2222-2222-222222222222/edit',
      ]) {
        router.go(path);
        await settle(tester);
        expect(locationOf(router), '/delivery/available', reason: 'ruta $path');
      }
    });

    testWidgets('rutas de cualquier usuario autenticado', (tester) async {
      for (final path in anyAuthenticated) {
        await expectResolves(tester, cliente, path);
      }
    });

    testWidgets('rutas de repartidor', (tester) async {
      for (final path in repartidorRoutes) {
        await expectResolves(tester, repartidor, path);
      }
    });

    testWidgets('la raíz verifica la sesión y lleva a cada rol a su inicio', (
      tester,
    ) async {
      var router = await pumpRouter(tester, null);
      expect(locationOf(router), '/login');

      router = await pumpRouter(tester, cliente);
      expect(locationOf(router), '/home');

      router = await pumpRouter(tester, repartidor);
      expect(locationOf(router), '/delivery/available');
    });
  });
}
