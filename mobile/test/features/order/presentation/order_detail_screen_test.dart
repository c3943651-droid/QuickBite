import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/external/enlaces_externos.dart';
import 'package:quickbite_mobile/src/core/utils/location_urls.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/widgets/delivery_map.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_tracking_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_launcher.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/order_fakes.dart';

const _session = AuthSession(
  tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
  user: AuthUser(
    id: '33333333-3333-3333-3333-333333333333',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

const _enCamino = Order(
  id: 'o1',
  numeroPedido: 'QB-20260927-AB12CD',
  estado: 'EnCamino',
  total: 171,
  direccionEntrega: 'Av. Reforma 222, Int 3, Casa, CDMX',
  items: [
    OrderItem(nombre: 'Tacos al pastor', cantidad: 2),
    OrderItem(nombre: 'Agua de horchata', cantidad: 1),
  ],
  subtotal: 150,
  costoEnvio: 21,
);

const _enCaminoConCoords = Order(
  id: 'o3',
  numeroPedido: 'QB-20260927-CC34EF',
  estado: 'EnCamino',
  total: 171,
  direccionEntrega: 'Av. Reforma 222, Int 3, Casa, CDMX',
  items: [OrderItem(nombre: 'Tacos al pastor', cantidad: 2)],
  subtotal: 150,
  costoEnvio: 21,
  latitud: 13.75,
  longitud: -89.15,
);

const _pendiente = Order(
  id: 'o2',
  numeroPedido: 'QB-20260927-ZZ00XX',
  estado: 'Pendiente',
  total: 100,
  direccionEntrega: 'Av. Reforma 222, Int 3, Casa, CDMX',
  items: [OrderItem(nombre: 'Burrito de carnitas', cantidad: 1)],
  subtotal: 80,
  costoEnvio: 20,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeOrderRepository orders;

  setUp(() {
    orders = FakeOrderRepository()..pedidos = [_enCamino, _pendiente];
  });

  /// Avanza el reloj y deja que las promesas pendientes terminen: un `pump` de
  /// un timer dispara el tick, pero el reprogramado ocurre en el siguiente.
  Future<void> avanzar(WidgetTester tester, Duration duracion) async {
    await tester.pump(duracion);
    await tester.pump(Duration.zero);
  }

  /// El polling corre con un intervalo corto para poder avanzar el reloj con
  /// `pump`; `pumpAndSettle` no se usa en esta pantalla porque nunca termina
  /// con un timer vivo.
  Future<ProviderContainer> pumpDetalle(
    WidgetTester tester, {
    Duration intervalo = const Duration(seconds: 10),
    String ordenId = 'o1',
    FakeExternalLauncher? launcher,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        intervaloPollingProvider.overrideWithValue(intervalo),
        if (launcher != null)
          externalLauncherProvider.overrideWithValue(launcher),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => _session);
    router.go('/order/$ordenId');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await avanzar(tester, const Duration(milliseconds: 100));
    return container;
  }

  /// Abre la hoja de confirmación y espera a que termine su animación: sin esto
  /// el botón de confirmar sigue fuera de la pantalla y el `tap` no impacta.
  Future<void> abrirHoja(WidgetTester tester) async {
    await tester.tap(find.text('Cancelar pedido'));
    await tester.pump();
    await avanzar(tester, const Duration(milliseconds: 400));
  }

  group('OrderDetailScreen (07.1 SCR-ORDER-01)', () {
    testWidgets('muestra número, estado, items, subtotal, envío y total', (
      tester,
    ) async {
      await pumpDetalle(tester);

      expect(find.text('QB-20260927-AB12CD'), findsOneWidget);
      expect(find.text('En camino'), findsWidgets);
      expect(find.text('2 × Tacos al pastor'), findsOneWidget);
      expect(find.text('1 × Agua de horchata'), findsOneWidget);
      expect(find.text(r'$150.00'), findsOneWidget);
      expect(find.text(r'$21.00'), findsOneWidget);
      expect(find.text(r'$171.00'), findsOneWidget);
    });

    testWidgets('muestra la dirección de entrega', (tester) async {
      await pumpDetalle(tester);

      expect(find.textContaining('Av. Reforma 222'), findsOneWidget);
    });

    testWidgets('la línea de tiempo marca el estado actual', (tester) async {
      await pumpDetalle(tester);

      expect(find.byKey(const ValueKey('timeline-current')), findsOneWidget);
      expect(find.text('En camino'), findsWidgets);
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
    });

    testWidgets('muestra el indicador mientras consulta y lo quita al parar', (
      tester,
    ) async {
      final consultaEnVuelo = Completer<void>();
      orders.statusGate = consultaEnVuelo;
      await pumpDetalle(tester, intervalo: const Duration(milliseconds: 300));

      expect(find.text('Actualizando...'), findsOneWidget);

      orders.statusGate = null;
      consultaEnVuelo.complete();
      await avanzar(tester, Duration.zero);

      expect(find.text('Actualizando...'), findsNothing);

      orders.estadoForzado = EstadoPedido.entregado;
      await avanzar(tester, const Duration(milliseconds: 300));
      await avanzar(tester, const Duration(milliseconds: 300));

      expect(find.text('Actualizando...'), findsNothing);
      expect(find.text('Entregado'), findsWidgets);
    });

    testWidgets('el polling vuelve a consultar el estado cada 10 s', (
      tester,
    ) async {
      await pumpDetalle(tester);
      final trasEntrada = orders.consultasStatus;

      await avanzar(tester, const Duration(seconds: 10));

      expect(orders.consultasStatus, greaterThan(trasEntrada));
    });

    testWidgets('en estado final deja de consultar', (tester) async {
      orders.estadoForzado = EstadoPedido.entregado;
      await pumpDetalle(tester, intervalo: const Duration(milliseconds: 100));
      await avanzar(tester, const Duration(milliseconds: 300));
      final alDetenerse = orders.consultasStatus;

      await avanzar(tester, const Duration(seconds: 30));

      expect(orders.consultasStatus, alDetenerse);
    });

    testWidgets('pausa el polling al pasar a segundo plano', (tester) async {
      final container = await pumpDetalle(
        tester,
        intervalo: const Duration(milliseconds: 100),
      );
      await avanzar(tester, const Duration(milliseconds: 200));

      container.read(orderTrackingProvider('o1').notifier).setVisible(false);
      final alPausar = orders.consultasStatus;
      await avanzar(tester, const Duration(milliseconds: 500));

      expect(orders.consultasStatus, alPausar);
    });

    testWidgets('al volver a primer plano reanuda el polling', (tester) async {
      final container = await pumpDetalle(
        tester,
        intervalo: const Duration(milliseconds: 100),
      );
      final notifier = container.read(orderTrackingProvider('o1').notifier)
        ..setVisible(false);
      await avanzar(tester, const Duration(milliseconds: 300));
      final alPausar = orders.consultasStatus;

      notifier.setVisible(true);
      await avanzar(tester, const Duration(milliseconds: 200));

      expect(orders.consultasStatus, greaterThan(alPausar));
    });
  });

  group('cancelación (07.1 SCR-ORDER-02)', () {
    testWidgets('solo ofrece cancelar si el pedido está pendiente', (
      tester,
    ) async {
      await pumpDetalle(tester);

      expect(find.text('Cancelar pedido'), findsNothing);
    });

    testWidgets('cancelar pide confirmación y motivo', (tester) async {
      orders.pedidos = [_pendiente];
      await pumpDetalle(tester, ordenId: 'o2');
      await abrirHoja(tester);

      expect(find.textContaining('Cancelar pedido'), findsWidgets);
      expect(find.text('Sí, cancelar pedido'), findsOneWidget);
    });

    testWidgets('confirmar la cancelación marca el pedido como cancelado', (
      tester,
    ) async {
      orders.pedidos = [_pendiente];
      await pumpDetalle(tester, ordenId: 'o2');
      await abrirHoja(tester);

      await tester.tap(find.text('Sí, cancelar pedido'));
      await tester.pump();
      await avanzar(tester, const Duration(milliseconds: 100));

      expect(orders.cancelaciones.single.motivo, '');
      expect(find.text('Cancelado'), findsWidgets);
      expect(find.text('Cancelar pedido'), findsNothing);
    });

    testWidgets('el motivo escrito se envía a la API', (tester) async {
      orders.pedidos = [_pendiente];
      await pumpDetalle(tester, ordenId: 'o2');
      await abrirHoja(tester);

      await tester.enterText(find.byType(TextField), 'Pedí mal la dirección');
      await tester.tap(find.text('Sí, cancelar pedido'));
      await tester.pump();
      await avanzar(tester, const Duration(milliseconds: 100));

      expect(orders.cancelaciones.single.motivo, 'Pedí mal la dirección');
    });

    testWidgets(
      'un rechazo de la API explica el motivo y no cambia el estado',
      (tester) async {
        orders.pedidos = [_pendiente];
        orders.cancelError = const ConflictException(
          'El pedido ya está en preparación.',
        );
        await pumpDetalle(tester, ordenId: 'o2');
        await abrirHoja(tester);

        await tester.tap(find.text('Sí, cancelar pedido'));
        await tester.pump();
        await avanzar(tester, const Duration(milliseconds: 100));

        expect(find.textContaining('en preparación'), findsOneWidget);
        expect(find.text('Pendiente'), findsWidgets);
        expect(find.byKey(const ValueKey('aviso-inline')), findsNothing);
      },
    );
  });

  group('estados no felices', () {
    testWidgets('un error al cargar muestra el mensaje y reintentar', (
      tester,
    ) async {
      orders.pedidos = [];
      orders.statusError = const NotFoundException();
      await pumpDetalle(tester);

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('un pedido entregado no ofrece cancelar', (tester) async {
      orders.pedidos = [_enCamino];
      orders.estadoForzado = EstadoPedido.entregado;
      await pumpDetalle(tester, intervalo: const Duration(milliseconds: 100));
      await avanzar(tester, const Duration(milliseconds: 200));

      expect(find.text('Cancelar pedido'), findsNothing);
    });
  });

  group('coordenadas y botones de apertura (07.5)', () {
    testWidgets(
      'con estado en camino y coordenadas muestra el destino real sin polyline',
      (tester) async {
        orders.pedidos = [_enCaminoConCoords];
        await pumpDetalle(tester, ordenId: 'o3');

        final mapa = tester.widget<DeliveryMap>(find.byType(DeliveryMap));
        expect(mapa.destination, const LatLng(13.75, -89.15));
        expect(mapa.routePolyline, isEmpty);
        expect(mapa.origin, const LatLng(13.6929, -89.2182));
      },
    );

    testWidgets('sin coordenadas oculta el mapa del detalle', (tester) async {
      orders.pedidos = [_enCamino];
      await pumpDetalle(tester, ordenId: 'o1');

      expect(find.byType(DeliveryMap), findsNothing);
    });

    testWidgets('ofrece Google Maps y Waze cuando hay coordenadas', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      orders.pedidos = [_enCaminoConCoords];
      await pumpDetalle(tester, ordenId: 'o3', launcher: launcher);

      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Waze'), findsOneWidget);
    });

    testWidgets('el botón de Google Maps abre la ubicación del pedido', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      orders.pedidos = [_enCaminoConCoords];
      await pumpDetalle(tester, ordenId: 'o3', launcher: launcher);

      await tester.tap(find.text('Google Maps'));
      await tester.pump();

      expect(launcher.uris, [googleMapsUri(13.75, -89.15)]);
    });

    testWidgets('el botón de Waze abre la ubicación del pedido', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      orders.pedidos = [_enCaminoConCoords];
      await pumpDetalle(tester, ordenId: 'o3', launcher: launcher);

      await tester.tap(find.text('Waze'));
      await tester.pump();

      expect(launcher.uris, [wazeUri(13.75, -89.15)]);
    });

    testWidgets('sin coordenadas no ofrece los botones de apertura', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      orders.pedidos = [_enCamino];
      await pumpDetalle(tester, launcher: launcher);

      expect(find.text('Google Maps'), findsNothing);
      expect(find.text('Waze'), findsNothing);
      expect(launcher.uris, isEmpty);
    });
  });
}
