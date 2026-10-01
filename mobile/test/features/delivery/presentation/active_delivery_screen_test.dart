import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/utils/location_urls.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/widgets/delivery_map.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/shell/pending_screen.dart';

import '../../../support/delivery_fakes.dart';
import '../../../support/fake_launcher.dart';
import '../../../support/router_harness.dart';

void main() {
  late FakeDeliveryRepository delivery;

  setUp(() => delivery = FakeDeliveryRepository());

  PedidoEntrega activa({
    String id = 'a1',
    String numero = 'QB-1001',
    double? latitud,
    double? longitud,
  }) {
    return PedidoEntrega(
      id: id,
      numeroPedido: numero,
      estado: EstadoPedido.enCamino.api,
      total: 250,
      creadoEn: DateTime.now().toUtc().subtract(const Duration(minutes: 25)),
      latitud: latitud,
      longitud: longitud,
    );
  }

  group('ActiveDeliveryScreen (07.1 SCR-DEL-03)', () {
    testWidgets('muestra el pedido en curso con su total', (tester) async {
      delivery.activa = activa();

      await pumpRepartidor(tester, delivery);
      await settle(tester);

      expect(find.text('QB-1001'), findsOneWidget);
      expect(find.text(r'$250.00'), findsOneWidget);
      expect(find.text('Marcar como entregado'), findsOneWidget);
    });

    testWidgets('muestra el tiempo transcurrido desde que se creó', (
      tester,
    ) async {
      delivery.activa = activa();

      await pumpRepartidor(tester, delivery);
      await settle(tester);

      expect(find.textContaining('25 min'), findsOneWidget);
    });

    testWidgets('sin entrega activa redirige a pedidos disponibles', (
      tester,
    ) async {
      final router = await pumpRepartidor(tester, delivery);
      await settle(tester);

      expect(locationOf(router), '/delivery/available');
    });

    testWidgets('completar pide confirmación antes de llamar a la API', (
      tester,
    ) async {
      delivery.activa = activa();
      await pumpRepartidor(tester, delivery);
      await settle(tester);

      await tester.tap(find.text('Marcar como entregado'));
      await tester.pumpAndSettle();

      expect(find.text('¿Marcar como entregado?'), findsOneWidget);
      expect(delivery.completados, isEmpty);
    });

    testWidgets('confirmar completa y vuelve a disponibles', (tester) async {
      delivery.activa = activa();
      final router = await pumpRepartidor(tester, delivery);
      await settle(tester);

      await tester.tap(find.text('Marcar como entregado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar como entregado').last);
      await tester.pumpAndSettle();
      await settle(tester);

      expect(delivery.completados, ['a1']);
      expect(locationOf(router), '/delivery/available');
    });

    testWidgets('cancelar la confirmación no completa nada', (tester) async {
      delivery.activa = activa();
      await pumpRepartidor(tester, delivery);
      await settle(tester);

      await tester.tap(find.text('Marcar como entregado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      expect(delivery.completados, isEmpty);
      expect(find.text('QB-1001'), findsOneWidget);
    });

    testWidgets('un fallo de la API al completar avisa y no navega', (
      tester,
    ) async {
      delivery.activa = activa();
      delivery.completarError = const ConflictException('El pedido ya cambió');
      final router = await pumpRepartidor(tester, delivery);
      await settle(tester);

      await tester.tap(find.text('Marcar como entregado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar como entregado').last);
      await tester.pumpAndSettle();

      expect(find.text('El pedido ya cambió'), findsOneWidget);
      expect(locationOf(router), '/delivery/active');
    });

    testWidgets('un fallo de carga muestra el error con reintentar', (
      tester,
    ) async {
      delivery.error = const ServerException();

      await pumpRepartidor(tester, delivery);
      await settle(tester);

      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('la pestaña de entrega activa ya no es una pantalla provisional', () {
    testWidgets('no muestra PendingScreen', (tester) async {
      delivery.activa = activa();

      await pumpRepartidor(tester, delivery);
      await settle(tester);

      expect(find.byType(PendingScreen), findsNothing);
    });
  });

  group('coordenadas y botones de apertura (07.5)', () {
    testWidgets('con permiso y coordenadas muestra el destino real', (
      tester,
    ) async {
      delivery.activa = activa(latitud: 13.75, longitud: -89.15);

      await pumpRepartidor(
        tester,
        delivery,
        permiso: LocationPermissionStatus.whenInUse,
      );
      await settle(tester);

      final mapa = tester.widget<DeliveryMap>(find.byType(DeliveryMap));
      expect(mapa.destination, const LatLng(13.75, -89.15));
      expect(mapa.origin, const LatLng(13.6929, -89.2182));
      expect(mapa.routePolyline, isEmpty);
    });

    testWidgets('sin coordenadas oculta el mapa y ofrece un aviso', (
      tester,
    ) async {
      delivery.activa = activa();

      await pumpRepartidor(
        tester,
        delivery,
        permiso: LocationPermissionStatus.whenInUse,
      );
      await settle(tester);

      expect(find.byType(DeliveryMap), findsNothing);
      expect(
        find.text('Este pedido no tiene coordenadas para mostrar en el mapa.'),
        findsOneWidget,
      );
    });

    testWidgets('con coordenadas ofrece Google Maps y Waze', (tester) async {
      delivery.activa = activa(latitud: 13.75, longitud: -89.15);

      await pumpRepartidor(tester, delivery);
      await settle(tester);

      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Waze'), findsOneWidget);
    });

    testWidgets('el botón de Google Maps abre la ubicación de entrega', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      delivery.activa = activa(latitud: 13.75, longitud: -89.15);

      await pumpRepartidor(tester, delivery, launcher: launcher);
      await settle(tester);

      await tester.tap(find.text('Google Maps'));
      await tester.pump();

      expect(launcher.uris, [googleMapsUri(13.75, -89.15)]);
    });

    testWidgets('el botón de Waze abre la ubicación de entrega', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      delivery.activa = activa(latitud: 13.75, longitud: -89.15);

      await pumpRepartidor(tester, delivery, launcher: launcher);
      await settle(tester);

      await tester.tap(find.text('Waze'));
      await tester.pump();

      expect(launcher.uris, [wazeUri(13.75, -89.15)]);
    });

    testWidgets('sin coordenadas no ofrece los botones de apertura', (
      tester,
    ) async {
      final launcher = FakeExternalLauncher();
      delivery.activa = activa();

      await pumpRepartidor(tester, delivery, launcher: launcher);
      await settle(tester);

      expect(find.text('Google Maps'), findsNothing);
      expect(find.text('Waze'), findsNothing);
      expect(launcher.uris, isEmpty);
    });
  });
}
