import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/available_orders_screen.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/delivery_fakes.dart';

void main() {
  late FakeDeliveryRepository delivery;

  setUp(() => delivery = FakeDeliveryRepository());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [deliveryRepositoryProvider.overrideWithValue(delivery)],
        child: const MaterialApp(home: AvailableOrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  PedidoEntrega pedido({
    String id = 'a1',
    String numero = 'QB-1001',
    String estado = 'Listo',
    double total = 250,
    int minutos = 12,
  }) {
    return PedidoEntrega(
      id: id,
      numeroPedido: numero,
      estado: estado,
      total: total,
      creadoEn: DateTime.now().toUtc().subtract(Duration(minutes: minutos)),
    );
  }

  group('AvailableOrdersScreen (07.1 SCR-DEL-01 y SCR-DEL-02)', () {
    testWidgets('lista los pedidos listos con número, total y tiempo', (
      tester,
    ) async {
      delivery.disponibles = [
        pedido(id: 'a1', numero: 'QB-1001', total: 250, minutos: 12),
        pedido(id: 'a2', numero: 'QB-1002', total: 480, minutos: 3),
      ];

      await pump(tester);

      expect(find.text('QB-1001'), findsOneWidget);
      expect(find.text('QB-1002'), findsOneWidget);
      expect(find.text(r'$250.00'), findsOneWidget);
      expect(find.text(r'$480.00'), findsOneWidget);
      expect(find.text('12 min'), findsOneWidget);
      expect(find.text('3 min'), findsOneWidget);
    });

    testWidgets('el título y el botón de refrescar están en el encabezado', (
      tester,
    ) async {
      delivery.disponibles = [pedido()];

      await pump(tester);

      expect(find.text('Pedidos disponibles'), findsOneWidget);
      final refrescar = find.byTooltip('Refrescar');
      expect(refrescar, findsOneWidget);
    });

    testWidgets('sin pedidos muestra la ilustración de lista vacía', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No hay pedidos disponibles'), findsOneWidget);
    });

    testWidgets('un fallo de la API muestra el error con reintentar', (
      tester,
    ) async {
      delivery.error = const ServerException();

      await pump(tester);

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('reintentar vuelve a consultar la API', (tester) async {
      delivery.error = const ServerException();
      await pump(tester);
      final consultasAntes = delivery.consultasDisponibles;

      delivery.error = null;
      delivery.disponibles = [pedido(numero: 'QB-7777')];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(delivery.consultasDisponibles, greaterThan(consultasAntes));
      expect(find.text('QB-7777'), findsOneWidget);
    });

    testWidgets('el refresco manual consulta sin esperar al polling', (
      tester,
    ) async {
      await pump(tester);
      final consultasAntes = delivery.consultasDisponibles;

      await tester.tap(find.byTooltip('Refrescar'));
      await tester.pumpAndSettle();

      expect(delivery.consultasDisponibles, greaterThan(consultasAntes));
    });

    testWidgets('el repartidor abre su perfil desde el encabezado', (
      tester,
    ) async {
      // El shell del repartidor tiene 3 pestañas y ninguna es el perfil
      // (07 §10.4), así que la puerta de entrada es el ícono del encabezado.
      delivery.disponibles = [pedido()];

      await pump(tester);
      final perfil = find.byTooltip('Perfil');
      expect(perfil, findsOneWidget);
    });

    testWidgets('el polling de 30 s vuelve a pedir los disponibles', (
      tester,
    ) async {
      await pump(tester);
      final consultasAntes = delivery.consultasDisponibles;

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(delivery.consultasDisponibles, greaterThan(consultasAntes));
    });

    testWidgets('salir de la pantalla detiene el polling', (tester) async {
      await pump(tester);
      final consultasTrasEntrar = delivery.consultasDisponibles;

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();

      expect(delivery.consultasDisponibles, consultasTrasEntrar);
    });

    testWidgets('mostrar el indicador mientras hay una consulta en vuelo', (
      tester,
    ) async {
      delivery.disponibles = [pedido()];
      delivery.gate = Completer<void>();
      // La petición queda colgada a propósito, así que `pumpAndSettle` no
      // sirve: se avanza el reloj un instante para que arranque la primera
      // consulta del polling.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [deliveryRepositoryProvider.overrideWithValue(delivery)],
          child: const MaterialApp(home: AvailableOrdersScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Actualizando...'), findsOneWidget);

      delivery.gate!.complete();
      // Sin `pumpAndSettle`: el polling de 30 s volvería a disparar y el
      // indicador aparecería de nuevo en la siguiente consulta.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Actualizando...'), findsNothing);
    });
  });

  group('aceptar entrega (07.1 SCR-DEL-02, 05#D-03)', () {
    testWidgets('pide confirmación antes de llamar a la API', (tester) async {
      delivery.disponibles = [pedido()];

      await pump(tester);
      await tester.tap(find.text('Aceptar entrega').first);
      await tester.pumpAndSettle();

      expect(find.text('¿Aceptar este pedido?'), findsOneWidget);
      expect(delivery.aceptados, isEmpty);
    });

    testWidgets('confirmar acepta el pedido y lo quita de la lista', (
      tester,
    ) async {
      delivery.disponibles = [pedido(id: 'a1', numero: 'QB-1001')];

      await pump(tester);
      await tester.tap(find.text('Aceptar entrega').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(delivery.aceptados, ['a1']);
      expect(find.text('QB-1001'), findsNothing);
    });

    testWidgets('cancelar la confirmación no llama a la API', (tester) async {
      delivery.disponibles = [pedido()];

      await pump(tester);
      await tester.tap(find.text('Aceptar entrega').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      expect(delivery.aceptados, isEmpty);
      expect(find.text('QB-1001'), findsOneWidget);
    });

    testWidgets('si la API lo rechaza, avisa y el pedido sigue disponible', (
      tester,
    ) async {
      delivery.disponibles = [pedido(id: 'a1', numero: 'QB-1001')];
      delivery.aceptarError = const ConflictException('Pedido ya asignado');

      await pump(tester);
      await tester.tap(find.text('Aceptar entrega').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido ya asignado'), findsOneWidget);
      expect(find.text('QB-1001'), findsOneWidget);
    });
  });

  group('estados que no se pueden aceptar', () {
    testWidgets('un pedido que no está listo muestra el botón desactivado', (
      tester,
    ) async {
      delivery.disponibles = [pedido(estado: EstadoPedido.enCamino.api)];

      await pump(tester);

      final boton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Aceptar entrega'),
      );
      expect(boton.onPressed, isNull);
    });
  });
}
