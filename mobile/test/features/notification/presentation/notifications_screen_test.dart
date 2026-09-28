import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/notification_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/notification_fakes.dart';

const _sesion = AuthSession(
  tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
  user: AuthUser(
    id: '33333333-3333-3333-3333-333333333333',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

const _pedidoId = '55555555-5555-5555-5555-555555555555';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeNotificationRepository notifications;

  setUp(() {
    notifications = FakeNotificationRepository(
      notificaciones: [
        Notificacion(
          id: 'n1',
          tipo: TipoNotificacion.cambioEstado,
          titulo: 'Tu pedido va en camino',
          mensaje: 'El repartidor ya salió.',
          pedidoId: _pedidoId,
          creadoEn: DateTime(2026, 9, 27, 15),
        ),
        Notificacion(
          id: 'n2',
          tipo: TipoNotificacion.sistema,
          titulo: 'Mantenimiento',
          mensaje: 'Domingo de mantenimiento.',
          creadoEn: DateTime(2026, 9, 26, 10),
        ),
      ],
    );
  });

  Future<({ProviderContainer container, GoRouter router})> pumpNotificaciones(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(notifications),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => _sesion);
    router.go('/notifications');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return (container: container, router: router);
  }

  group('NotificationsScreen (07.1 SCR-NOTIF-01)', () {
    testWidgets('lista las notificaciones con los cuatro filtros', (
      tester,
    ) async {
      await pumpNotificaciones(tester);

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('No leídas'), findsOneWidget);
      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
      expect(find.text('Tu pedido va en camino'), findsOneWidget);
      expect(find.text('El repartidor ya sali\u00f3.'), findsOneWidget);
      expect(find.text('Mantenimiento'), findsOneWidget);
    });

    testWidgets('el filtro No leídas oculta lo ya leído', (tester) async {
      await pumpNotificaciones(tester);

      await tester.tap(find.text('Marcar todas como leídas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('No leídas'));
      await tester.pump();

      expect(find.text('Tu pedido va en camino'), findsNothing);
      expect(
        find.text('No tienes notificaciones en este filtro.'),
        findsOneWidget,
      );
    });

    testWidgets('resalta las no leídas y el contador del encabezado', (
      tester,
    ) async {
      await pumpNotificaciones(tester);

      expect(find.text('2 sin leer'), findsOneWidget);
      expect(find.byKey(const ValueKey('no-leida-n1')), findsOneWidget);
      expect(find.byKey(const ValueKey('no-leida-n2')), findsOneWidget);
    });

    testWidgets('tocar una notificación la marca como leída', (tester) async {
      await pumpNotificaciones(tester);

      await tester.tap(find.text('Mantenimiento'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifications.leidas, ['n2']);
      expect(find.text('1 sin leer'), findsOneWidget);
    });

    testWidgets('tocar una notificación de pedido abre su seguimiento', (
      tester,
    ) async {
      final (:container, :router) = await pumpNotificaciones(tester);

      await tester.tap(find.text('Tu pedido va en camino'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(notifications.leidas, ['n1']);
      expect(router.state.uri.path, '/order/$_pedidoId');
      expect(
        container.read(notificationRepositoryProvider),
        same(notifications),
      );
    });

    testWidgets('marcar todas deja la bandeja sin pendientes', (tester) async {
      await pumpNotificaciones(tester);

      await tester.tap(find.text('Marcar todas como leídas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifications.todasMarcadas, 1);
      expect(find.text('0 sin leer'), findsOneWidget);
    });

    testWidgets('un error de carga muestra el mensaje y reintenta', (
      tester,
    ) async {
      notifications.listError = const ServerException('No pudimos cargar.');
      await pumpNotificaciones(tester);

      expect(find.textContaining('No pudimos cargar'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      notifications.listError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tu pedido va en camino'), findsOneWidget);
    });

    testWidgets('una bandeja vacía explica que no hay notificaciones', (
      tester,
    ) async {
      notifications.notificaciones = [];
      await pumpNotificaciones(tester);

      expect(find.text('No tienes notificaciones.'), findsOneWidget);
    });
  });
}
