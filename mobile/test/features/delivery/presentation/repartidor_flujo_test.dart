import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/widgets/delivery_map.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/delivery_fakes.dart';
import '../../../support/router_harness.dart';

/// Flujo completo del repartidor, sin pruebas manuales:
///
/// asignado → la pantalla activa lo refleja con sus detalles → el mapa carga →
/// se marca entregado → vuelve a la lista.
///
/// Cubre lo que rompía el reflejo de pedidos asignados: con el pedido ya
/// asignado, la pantalla activa tiene que mostrarlo (y no redirigir) en cuanto
/// se entra, y tras completar tiene que devolver al repartidor a disponibles.
void main() {
  late FakeDeliveryRepository delivery;

  setUp(() => delivery = FakeDeliveryRepository());

  PedidoEntrega asignado({
    String id = 'a1',
    String numero = 'QB-2001',
    String? cliente = 'Ana Pérez',
    String? direccion = 'Av. Olímpica 56, San Salvador',
    String? telefono = '+50312345678',
    List<String> items = const ['2 × Doble Carne', '1 × Dona Clásica'],
    double? latitud = 13.70,
    double? longitud = -89.21,
  }) => PedidoEntrega(
    id: id,
    numeroPedido: numero,
    estado: EstadoPedido.enCamino.api,
    total: 258.50,
    subtotal: 258.50,
    items: items,
    cliente: cliente,
    direccion: direccion,
    telefono: telefono,
    creadoEn: DateTime.now().toUtc().subtract(const Duration(minutes: 12)),
    latitud: latitud,
    longitud: longitud,
  );

  group('flujo del repartidor', () {
    testWidgets('pedido asignado: la pantalla activa lo refleja con detalles', (
      tester,
    ) async {
      delivery.activa = asignado();

      final router = await pumpRepartidor(
        tester,
        delivery,
        permiso: LocationPermissionStatus.whenInUse,
      );
      await settle(tester);

      // No redirige: hay entrega que hacer.
      expect(locationOf(router), '/delivery/active');

      // Cliente, dirección, teléfono, qué llevar y total a cobrar.
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Av. Olímpica 56, San Salvador'), findsOneWidget);
      expect(find.text('Llamar al cliente'), findsOneWidget);
      expect(find.text('Qué llevar'), findsOneWidget);
      expect(find.text('• 2 × Doble Carne'), findsOneWidget);
      expect(find.text('Total a cobrar'), findsOneWidget);
      expect(find.text(r'$258.50'), findsOneWidget);
    });

    testWidgets('el mapa carga con restaurante, cliente y repartidor', (
      tester,
    ) async {
      delivery.activa = asignado();

      await pumpRepartidor(
        tester,
        delivery,
        permiso: LocationPermissionStatus.whenInUse,
      );
      await settle(tester);

      expect(find.byType(DeliveryMap), findsOneWidget);
      final mapa = tester.widget<DeliveryMap>(find.byType(DeliveryMap));
      expect(mapa.destination.latitude, 13.70);
      expect(mapa.originTitle, 'QuickBite');
      // Sin GPS del repartidor el mapa se dibuja igual, sin su marcador.
      expect(mapa.riderLocation, isNull);
    });

    testWidgets('sin coordenadas el mapa avisa en vez de romperse', (
      tester,
    ) async {
      delivery.activa = asignado(latitud: null, longitud: null);

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
      // Los detalles siguen visibles: perder el mapa no pierde el pedido.
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pedido sin datos de contacto no rompe la pantalla', (
      tester,
    ) async {
      delivery.activa = asignado(
        cliente: null,
        direccion: null,
        telefono: null,
      );

      await pumpRepartidor(
        tester,
        delivery,
        permiso: LocationPermissionStatus.whenInUse,
      );
      await settle(tester);

      expect(find.text('Llamar al cliente'), findsNothing);
      expect(find.text('Total a cobrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('marcar entregado devuelve a la lista y registra el cambio', (
      tester,
    ) async {
      delivery.activa = asignado();

      final router = await pumpRepartidor(
        tester,
        delivery,
        permiso: LocationPermissionStatus.whenInUse,
      );
      await settle(tester);

      await tester.tap(find.text('Marcar como entregado'));
      await settle(tester);
      await tester.tap(find.text('Marcar como entregado').last);
      await settle(tester);

      expect(delivery.completados, ['a1']);
      expect(delivery.activa, isNull);
      expect(locationOf(router), '/delivery/available');
    });
  });
}
