import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_history_screen.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/delivery_fakes.dart';

void main() {
  late FakeDeliveryRepository delivery;

  setUp(() => delivery = FakeDeliveryRepository());

  PedidoEntrega entrega({
    required String id,
    String numero = 'QB-1001',
    String estado = 'Entregado',
    double total = 250,
    Duration hace = const Duration(days: 1),
  }) {
    return PedidoEntrega(
      id: id,
      numeroPedido: numero,
      estado: estado,
      total: total,
      creadoEn: DateTime.now().toUtc().subtract(hace),
    );
  }

  Future<GoRouter> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/delivery/history',
      routes: [
        GoRoute(
          path: '/delivery/history',
          builder: (context, state) => const DeliveryHistoryScreen(),
        ),
        GoRoute(
          path: '/delivery/history/:id',
          builder: (context, state) => DeliveryHistoryDetailScreen(
            pedidoId: state.pathParameters['id']!,
          ),
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

  group('DeliveryHistoryScreen (07.1 SCR-DEL-04)', () {
    testWidgets('lista las entregas con número, total y fecha', (tester) async {
      delivery.historial = [
        entrega(id: 'h1', numero: 'QB-1001', total: 250),
        entrega(
          id: 'h2',
          numero: 'QB-0999',
          total: 480,
          hace: const Duration(days: 9),
        ),
      ];

      await pump(tester);

      expect(find.text('QB-1001'), findsOneWidget);
      expect(find.text('QB-0999'), findsOneWidget);
      expect(find.text(r'$250.00'), findsOneWidget);
      expect(find.text(r'$480.00'), findsOneWidget);
    });

    testWidgets('el filtro de fecha por defecto es "Todo"', (tester) async {
      await pump(tester);

      expect(
        find.widgetWithText(AppBar, 'Historial de entregas'),
        findsOneWidget,
      );
      expect(find.text('Todo'), findsOneWidget);
    });

    testWidgets('"Hoy" oculta las entregas de días anteriores', (tester) async {
      delivery.historial = [
        entrega(id: 'h1', numero: 'QB-HOY', hace: const Duration(minutes: 30)),
        entrega(id: 'h2', numero: 'QB-VIEJO', hace: const Duration(days: 6)),
      ];

      await pump(tester);
      await tester.tap(find.text('Todo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoy').last);
      await tester.pumpAndSettle();

      expect(find.text('QB-HOY'), findsOneWidget);
      expect(find.text('QB-VIEJO'), findsNothing);
    });

    testWidgets('"Semana" deja las de hasta siete días', (tester) async {
      delivery.historial = [
        entrega(id: 'h1', numero: 'QB-RECIENTE', hace: const Duration(days: 2)),
        entrega(id: 'h2', numero: 'QB-ANTIGUO', hace: const Duration(days: 20)),
      ];

      await pump(tester);
      await tester.tap(find.text('Todo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semana').last);
      await tester.pumpAndSettle();

      expect(find.text('QB-RECIENTE'), findsOneWidget);
      expect(find.text('QB-ANTIGUO'), findsNothing);
    });

    testWidgets('sin entregas muestra la ilustración de vacío', (tester) async {
      await pump(tester);

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Todavía no tienes entregas'), findsOneWidget);
    });

    testWidgets('un fallo de la API muestra el error con reintentar', (
      tester,
    ) async {
      delivery.error = const ServerException();

      await pump(tester);

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('tocar una entrega abre su detalle', (tester) async {
      delivery.historial = [entrega(id: 'h1', numero: 'QB-1001')];

      await pump(tester);
      await tester.tap(find.text('QB-1001'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fecha y hora de entrega'), findsOneWidget);
    });
  });

  group('DeliveryHistoryDetailScreen (07.1 SCR-DEL-05)', () {
    testWidgets('muestra el número, el total y la fecha de entrega', (
      tester,
    ) async {
      delivery.historial = [entrega(id: 'h1', numero: 'QB-1001', total: 250)];

      final router = await pump(tester);
      router.go('/delivery/history/h1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('QB-1001'), findsOneWidget);
      expect(find.text(r'$250.00'), findsOneWidget);
      expect(find.text('Tiempo total de entrega'), findsOneWidget);
    });

    testWidgets(
      'un id desconocido avisa en vez de mostrar una pantalla en blanco',
      (tester) async {
        delivery.historial = [entrega(id: 'h1')];

        final router = await pump(tester);
        router.go('/delivery/history/no-existe');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('No encontramos esa entrega'), findsOneWidget);
      },
    );
  });

  group('estados filtrados', () {
    testWidgets('un pedido cancelado no aparece en el historial', (
      tester,
    ) async {
      delivery.historial = [
        entrega(id: 'h1', numero: 'QB-OK'),
        entrega(
          id: 'h2',
          numero: 'QB-CANCELADO',
          estado: EstadoPedido.cancelado.api,
        ),
      ];

      await pump(tester);

      expect(find.text('QB-OK'), findsOneWidget);
      expect(find.text('QB-CANCELADO'), findsNothing);
    });
  });
}
