import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/available_order_detail_screen.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/delivery_fakes.dart';

void main() {
  late FakeDeliveryRepository delivery;

  setUp(() => delivery = FakeDeliveryRepository());

  Future<GoRouter> pump(WidgetTester tester, String pedidoId) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // La pantalla navega a la entrega activa al aceptar, así que necesita un
    // router de verdad: `context.go` sin router lanza.
    final router = GoRouter(
      initialLocation: '/delivery/available/$pedidoId',
      routes: [
        GoRoute(
          path: '/delivery/available/:id',
          builder: (context, state) =>
              AvailableOrderDetailScreen(pedidoId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/delivery/active',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('entrega activa'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [deliveryRepositoryProvider.overrideWithValue(delivery)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return router;
  }

  PedidoEntrega pedido({String id = 'a1', String estado = 'Listo'}) {
    return PedidoEntrega(
      id: id,
      numeroPedido: 'QB-1001',
      estado: estado,
      total: 250,
      creadoEn: DateTime.now().toUtc().subtract(const Duration(minutes: 8)),
    );
  }

  group('AvailableOrderDetailScreen (07.1 SCR-DEL-02)', () {
    testWidgets('muestra el número de pedido y el total', (tester) async {
      delivery.disponibles = [pedido()];

      await pump(tester, 'a1');

      expect(find.text('QB-1001'), findsOneWidget);
      expect(find.text(r'$250.00'), findsOneWidget);
    });

    testWidgets('el botón de aceptar lleva a la confirmación', (tester) async {
      delivery.disponibles = [pedido()];

      await pump(tester, 'a1');
      await tester.tap(find.text('Aceptar entrega'));
      await tester.pumpAndSettle();

      expect(find.text('¿Aceptar este pedido?'), findsOneWidget);
      expect(delivery.aceptados, isEmpty);
    });

    testWidgets('confirmar acepta el pedido y abre la entrega activa', (
      tester,
    ) async {
      delivery.disponibles = [pedido()];

      final router = await pump(tester, 'a1');
      await tester.tap(find.text('Aceptar entrega'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();

      expect(delivery.aceptados, ['a1']);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/delivery/active',
      );
    });

    testWidgets('un id que no está en la lista avisa y no ofrece aceptar', (
      tester,
    ) async {
      delivery.disponibles = [pedido(id: 'otra')];

      await pump(tester, 'a1');

      expect(find.text('Este pedido ya no está disponible'), findsOneWidget);
      expect(find.text('Aceptar entrega'), findsNothing);
    });

    testWidgets('un fallo de la API avisa y mantiene el pedido', (
      tester,
    ) async {
      delivery.disponibles = [pedido()];
      delivery.aceptarError = const ConflictException('Pedido ya asignado');

      await pump(tester, 'a1');
      await tester.tap(find.text('Aceptar entrega'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido ya asignado'), findsOneWidget);
      expect(find.text('QB-1001'), findsOneWidget);
    });

    testWidgets('un pedido que ya no está listo no se puede aceptar', (
      tester,
    ) async {
      delivery.disponibles = [pedido(estado: EstadoPedido.entregado.api)];

      await pump(tester, 'a1');

      final boton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Aceptar entrega'),
      );
      expect(boton.onPressed, isNull);
    });
  });
}
