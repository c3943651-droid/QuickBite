import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/widgets/metric_card.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/estadisticas_repartidor.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_stats_screen.dart';

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
        child: const MaterialApp(home: DeliveryStatsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('DeliveryStatsScreen (07.1 SCR-DEL-06)', () {
    testWidgets('muestra las cinco métricas', (tester) async {
      delivery.stats = const EstadisticasRepartidor(
        entregasTotales: 42,
        entregasDelMes: 7,
        tiempoPromedioEntregaMinutos: 23.5,
        pedidosAsignados: 2,
        cancelaciones: 1,
      );

      await pump(tester);

      expect(find.text('Entregas totales'), findsOneWidget);
      expect(find.text('Entregas del mes'), findsOneWidget);
      expect(find.text('Tiempo promedio de entrega'), findsOneWidget);
      expect(find.text('Pedidos asignados'), findsOneWidget);
      expect(find.text('Cancelaciones'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('23.5'), findsOneWidget);
    });

    testWidgets('sin datos muestra ceros y el mensaje de "aún no tienes"', (
      tester,
    ) async {
      delivery.stats = const EstadisticasRepartidor.vacias();

      await pump(tester);

      expect(find.text('Aún no tienes entregas'), findsOneWidget);
      expect(find.byType(MetricCard), findsNWidgets(5));
      // Los cuatro contadores son enteros; el promedio es double y sale "0.0".
      expect(find.text('0'), findsNWidgets(4));
      expect(find.text('0.0'), findsOneWidget);
    });

    testWidgets('un fallo de la API muestra el error con reintentar', (
      tester,
    ) async {
      delivery.error = const ServerException();

      await pump(tester);

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('mientras carga muestra el spinner y ninguna tarjeta', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [deliveryRepositoryProvider.overrideWithValue(delivery)],
          child: const MaterialApp(home: DeliveryStatsScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MetricCard), findsNothing);
    });
  });
}
