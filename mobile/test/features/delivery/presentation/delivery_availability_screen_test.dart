import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/disponibilidad.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_availability_screen.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';

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
        child: const MaterialApp(home: DeliveryAvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('DeliveryAvailabilityScreen (07.1 SCR-DEL-07)', () {
    testWidgets('muestra el interruptor con el estado actual', (tester) async {
      delivery.estado = DeliveryPersonStatus.disponible;

      await pump(tester);

      expect(
        find.text('Estoy disponible para recibir pedidos'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsOneWidget);
      expect(
        tester.widget<Switch>(find.byType(Switch)).value,
        isTrue,
        reason: 'el repartidor disponible tiene el interruptor encendido',
      );
    });

    testWidgets('cambiar el interruptor llama a la API', (tester) async {
      delivery.estado = DeliveryPersonStatus.disponible;

      await pump(tester);
      await tester.tap(find.byType(Switch));
      await asentar(tester);

      expect(delivery.cambiosDisponibilidad, [DeliveryPersonStatus.inactivo]);
    });

    testWidgets('con entrega activa, volver a disponible se revierte', (
      tester,
    ) async {
      delivery.estado = DeliveryPersonStatus.disponible;
      delivery.tieneEntregaActiva = true;
      // El backend responde 409 (BusinessRuleException) y la app lo traduce
      // a ConflictException conservando el mensaje.
      delivery.cambiarDisponibilidadError = const ConflictException(
        'No puedes marcarte disponible con una entrega en camino',
      );

      await pump(tester);
      await tester.tap(find.byType(Switch));
      await asentar(tester);

      expect(
        find.text('No puedes marcarte disponible con una entrega en camino'),
        findsOneWidget,
      );
      // El interruptor vuelve a su posición: la API es la fuente de verdad.
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('avisa que no puede marcarse disponible con entrega activa', (
      tester,
    ) async {
      delivery.estado = DeliveryPersonStatus.disponible;
      delivery.tieneEntregaActiva = true;

      await pump(tester);

      expect(
        find.textContaining('no puede marcarse como disponible'),
        findsOneWidget,
      );
    });

    testWidgets('un fallo al cargar muestra el error con reintentar', (
      tester,
    ) async {
      delivery.estadoError = const ServerException();

      await pump(tester);

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}

/// Bomba lo justo para que se resuelvan las peticiones asíncronas.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 300));
}
