import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

const _session = AuthSession(
  tokens: AuthTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresIn: 3600,
  ),
  user: AuthUser(
    id: '1',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

const _config = AppConfig(
  apiBaseUrl: 'https://api.test',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 10),
);

Future<GoRouter> pumpRouter(WidgetTester tester, AuthSession? session) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createRouter(() async => session);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(_config)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return router;
}

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  group('createRouter', () {
    testWidgets('sin sesión, /home redirige a /login', (tester) async {
      final router = await pumpRouter(tester, null);

      expect(locationOf(router), '/login');
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });

    testWidgets('con sesión, /home se muestra el catálogo', (tester) async {
      final router = await pumpRouter(tester, _session);

      expect(locationOf(router), '/home');
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('sin sesión, / redirige a /login', (tester) async {
      final router = await pumpRouter(tester, null);

      expect(locationOf(router), '/login');
    });

    testWidgets('con sesión, /login redirige a /home', (tester) async {
      final router = await pumpRouter(tester, _session);

      expect(locationOf(router), '/home');
    });

    testWidgets('sin sesión, /register es accesible', (tester) async {
      final router = await pumpRouter(tester, null);
      router.go('/register');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(locationOf(router), '/register');
      expect(find.text('Crea tu cuenta'), findsOneWidget);
    });

    testWidgets('el shell muestra el catálogo y las cuatro secciones', (
      tester,
    ) async {
      await pumpRouter(tester, _session);

      expect(find.text('Catálogo'), findsOneWidget);
      expect(find.text('Carrito'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets(
      'las secciones no disponibles informan en vez de fallar en silencio',
      (tester) async {
        final router = await pumpRouter(tester, _session);

        await tester.tap(find.text('Carrito'));
        await tester.pump();

        expect(
          find.text('El carrito llegará en el próximo hito.'),
          findsOneWidget,
        );
        expect(locationOf(router), '/home');
      },
    );
  });
}
