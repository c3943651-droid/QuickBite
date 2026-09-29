import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

/// SCR-COM-03: cuando la sesión deja de ser válida estando dentro de la app,
/// el router debe llevar a /login avisando con snackbar.
///
/// El flujo de red (401 → POST /auth/refresh → 401) ya está cubierto en
/// `token_refresh_flow_test.dart`; aquí se aísla la reacción del router.
const _config = AppConfig(
  apiBaseUrl: 'https://api.test/api/v1',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 10),
  supportEmail: 'soporte@test.mx',
  legalBaseUrl: 'https://test.mx/legal',
);

const _session = AuthSession(
  tokens: AuthTokens(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresIn: 3600,
  ),
  user: AuthUser(
    id: '1',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('SCR-COM-03: la sesión expirada redirige a /login con snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AuthSession? session = _session;
    var expiry = SessionExpiry.none;
    final router = createRouter(() async => session, readExpiry: () => expiry);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(_config)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(locationOf(router), '/home', reason: 'parte de una sesión activa');

    // La renovación falló: la sesión deja de ser válida sin que el usuario
    // haya navegado a ninguna parte.
    session = null;
    expiry = SessionExpiry.refreshFailed;
    router.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 4));

    expect(locationOf(router), '/login');
    expect(find.text('Tu sesión ha expirado'), findsOneWidget);
  });
}
