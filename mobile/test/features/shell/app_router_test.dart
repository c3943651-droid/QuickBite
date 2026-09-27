import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';

import '../../support/router_harness.dart';

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
  });
}
