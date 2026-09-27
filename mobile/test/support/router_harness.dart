import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

const testConfig = AppConfig(
  apiBaseUrl: 'https://api.test',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 10),
);

AuthSession sessionFor(String rol) {
  return AuthSession(
    tokens: const AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresIn: 3600,
    ),
    user: AuthUser(
      id: '1',
      nombre: 'Carlos Pérez',
      email: 'carlos@quickbite.mx',
      rol: rol,
    ),
  );
}

/// Sesión fija para que el guard y `MainShell` vean la misma fuente de
/// verdad, igual que en la app real.
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final AuthSession? session;

  @override
  Future<AuthSession?> build() async => session;
}

/// Monta la app con una sesión fija y devuelve el router para poder navegar y
/// consultar la ubicación actual.
Future<GoRouter> pumpRouter(
  WidgetTester tester,
  AuthSession? session, {
  SessionExpiry expiry = SessionExpiry.none,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createRouter(() async => session, readExpiry: () => expiry);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        sessionProvider.overrideWith(() => _FixedSessionNotifier(session)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return router;
}

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

/// `pumpAndSettle` no sirve en este archivo: el catálogo real mantiene
/// temporizadores vivos (debounce, reintentos), así que nunca llega un frame
/// quieto. Se avanza un tiempo fijo y suficiente para que terminen la
/// redirección del guard y las animaciones de la barra de pestañas.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Localizador de la pantalla provisional que sustituye a una ficha `SCR-*`
/// cuyo hito todavía no ha llegado.
Finder pendingAt(String path) => find.byKey(ValueKey('pending:$path'));
