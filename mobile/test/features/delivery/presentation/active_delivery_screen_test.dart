import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/shell/pending_screen.dart';

import '../../../support/delivery_fakes.dart';
import '../../../support/router_harness.dart';

void main() {
  late FakeDeliveryRepository delivery;

  setUp(() => delivery = FakeDeliveryRepository());

  PedidoEntrega activa({String id = 'a1', String numero = 'QB-1001'}) {
    return PedidoEntrega(
      id: id,
      numeroPedido: numero,
      estado: EstadoPedido.enCamino.api,
      total: 250,
      creadoEn: DateTime.now().toUtc().subtract(const Duration(minutes: 25)),
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
}
