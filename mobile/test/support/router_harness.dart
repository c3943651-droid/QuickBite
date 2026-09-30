import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/delivery_repository.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import 'package:quickbite_mobile/src/features/delivery/data/location_permission_service.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';

import 'cart_fakes.dart';
import 'delivery_fakes.dart';

class FakeLocationPermissionService implements LocationPermissionService {
  @override
  Future<LocationPermissionStatus> checkStatus() async =>
      LocationPermissionStatus.notDetermined;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.notDetermined;
}

const testConfig = AppConfig(
  apiBaseUrl: 'https://api.test',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 10),
  supportEmail: 'soporte@test.mx',
  legalBaseUrl: 'https://test.mx/legal',
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
  DeliveryRepository? delivery,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  // Inset del sistema (3 botones, 120 px físicos) para que las `SafeArea` se
  // comporten como en el Moto G15 en vez de como en una pantalla sin barras.
  tester.view.padding = const FakeViewPadding(top: 51, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 51, bottom: 48);
  addTearDown(tester.view.reset);

  final router = createRouter(() async => session, readExpiry: () => expiry);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        sessionProvider.overrideWith(() => _FixedSessionNotifier(session)),
        cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        locationPermissionServiceProvider
            .overrideWithValue(FakeLocationPermissionService()),
        if (delivery != null)
          deliveryRepositoryProvider.overrideWithValue(delivery),
      ],
      child: MaterialApp.router(routerConfig: router, theme: theme),
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

/// Monta la app con una sesión de repartidor y el repositorio de entregas del
/// test. Devuelve el router para comprobar a dónde saltó la pantalla.
Future<GoRouter> pumpRepartidor(
  WidgetTester tester,
  FakeDeliveryRepository delivery, {
  String location = '/delivery/active',
}) async {
  final router = await pumpRouter(
    tester,
    sessionFor('repartidor'),
    delivery: delivery,
  );
  if (location != router.routerDelegate.currentConfiguration.uri.path) {
    router.go(location);
    await settle(tester);
  }
  return router;
}
