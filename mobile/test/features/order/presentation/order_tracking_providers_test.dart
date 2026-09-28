import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/polling/polling_controller.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_tracking_providers.dart';

import '../../../support/order_fakes.dart';

const _ordenId = 'o1';

void main() {
  late FakeOrderRepository repo;
  late ProviderContainer container;

  const pedidoPendiente = Order(
    id: _ordenId,
    numeroPedido: 'QB-1',
    estado: 'Pendiente',
    total: 171,
    direccionEntrega: 'Av. Reforma 222, CDMX',
    items: [OrderItem(nombre: 'Tacos al pastor', cantidad: 2)],
    subtotal: 150,
    costoEnvio: 21,
  );

  OrderTrackingState estado() =>
      container.read(orderTrackingProvider(_ordenId));

  ProviderContainer crearContainer({
    Duration intervalo = const Duration(seconds: 10),
  }) {
    final c = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repo),
        intervaloPollingProvider.overrideWithValue(intervalo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repo = FakeOrderRepository()..pedidos = [pedidoPendiente];
  });

  group('carga inicial', () {
    test('trae el detalle del pedido al abrir la pantalla', () async {
      container = crearContainer();

      expect(estado().cargando, isTrue);
      await _esperar();

      expect(estado().cargando, isFalse);
      expect(estado().pedido?.numeroPedido, 'QB-1');
      expect(estado().pedido?.subtotal, 150);
      expect(estado().pedido?.cantidadItems, 2);
      expect(estado().error, isNull);
    });

    test(
      'un pedido inexistente deja mensaje y reintentar vuelve a cargar',
      () async {
        repo.pedidos = [];
        container = crearContainer();
        container.read(orderTrackingProvider(_ordenId));
        await _esperar();

        expect(estado().pedido, isNull);
        expect(estado().cargando, isFalse);
        expect(estado().error, isNotNull);

        repo.pedidos = [pedidoPendiente];
        await container
            .read(orderTrackingProvider(_ordenId).notifier)
            .recargar();
        await _esperar();

        expect(estado().pedido?.numeroPedido, 'QB-1');
        expect(estado().error, isNull);
      },
    );
  });

  group('polling', () {
    test('consulta el estado periódicamente mientras siga activo', () async {
      container = crearContainer(intervalo: const Duration(milliseconds: 30));
      container.read(orderTrackingProvider(_ordenId));
      await _esperar();

      final consultasIniciales = repo.consultasStatus;
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(repo.consultasStatus, greaterThan(consultasIniciales));
      expect(estado().consultando, isFalse);
    });

    test('el estado que llega por polling se refleja en pantalla', () async {
      container = crearContainer(intervalo: const Duration(milliseconds: 30));
      container.read(orderTrackingProvider(_ordenId));
      await _esperar();
      repo.estadoForzado = EstadoPedido.enCamino;

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(estado().pedido?.estado, 'EnCamino');
      expect(estado().estado, EstadoPedido.enCamino);
    });

    test('se detiene al llegar a un estado final', () async {
      repo.estadoForzado = EstadoPedido.entregado;
      container = crearContainer(intervalo: const Duration(milliseconds: 30));
      container.read(orderTrackingProvider(_ordenId));
      await _esperar();

      final alDetenerse = repo.consultasStatus;
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(estado().estado, EstadoPedido.entregado);
      expect(estado().pollingActivo, isFalse);
      expect(
        repo.consultasStatus,
        alDetenerse,
        reason: 'entregado es estado final: no vuelve a consultar',
      );
    });

    test('cancelado también detiene el polling', () async {
      repo.estadoForzado = EstadoPedido.cancelado;
      container = crearContainer(intervalo: const Duration(milliseconds: 30));
      container.read(orderTrackingProvider(_ordenId));
      await _esperar();
      final alDetenerse = repo.consultasStatus;

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(estado().pollingActivo, isFalse);
      expect(repo.consultasStatus, alDetenerse);
    });

    test('salir de la pantalla detiene el polling', () async {
      container = crearContainer(intervalo: const Duration(milliseconds: 30));
      container.read(orderTrackingProvider(_ordenId));
      await _esperar();
      container.read(orderTrackingProvider(_ordenId).notifier).detener();
      final alDetenerse = repo.consultasStatus;

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(repo.consultasStatus, alDetenerse);
    });

    test('la app en segundo plano pausa y al volver reanuda', () async {
      container = crearContainer(intervalo: const Duration(milliseconds: 30));
      final notifier = container.read(orderTrackingProvider(_ordenId).notifier);
      await _esperar();

      notifier.setVisible(false);
      final alPausar = repo.consultasStatus;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(repo.consultasStatus, alPausar);

      notifier.setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(repo.consultasStatus, greaterThan(alPausar));
    });

    test(
      'el estado final también detiene el indicador de actualización',
      () async {
        repo.estadoForzado = EstadoPedido.entregado;
        container = crearContainer(intervalo: const Duration(milliseconds: 30));
        container.read(orderTrackingProvider(_ordenId));
        await _esperar();

        expect(estado().consultando, isFalse);
        expect(estado().pollingActivo, isFalse);
      },
    );

    test(
      'con la app visible y el pedido activo el polling sigue corriendo',
      () {
        container = crearContainer();
        container.read(orderTrackingProvider(_ordenId));

        final controller = container
            .read(orderTrackingProvider(_ordenId).notifier)
            .polling;
        expect(controller.intervalo, FrecuenciaPolling.porDefecto);
      },
    );
  });

  group('cancelación', () {
    test('cancela con el motivo y refleja el estado cancelado', () async {
      container = crearContainer();
      final notifier = container.read(orderTrackingProvider(_ordenId).notifier);
      await _esperar();

      final ok = await notifier.cancelar('Me equivoqué de dirección');

      expect(ok, isTrue);
      expect(repo.cancelaciones.single.motivo, 'Me equivoqué de dirección');
      expect(estado().estado, EstadoPedido.cancelado);
      expect(estado().pollingActivo, isFalse);
    });

    test('el botón solo aparece con el pedido cancelable', () async {
      container = crearContainer();
      final notifier = container.read(orderTrackingProvider(_ordenId).notifier);
      await _esperar();

      expect(estado().puedeCancelar, isTrue);
      await notifier.cancelar('me arrepentí');
      expect(estado().puedeCancelar, isFalse);
    });

    test('un rechazo deja el pedido como estaba y avisa del motivo', () async {
      repo.cancelError = ConflictException('El pedido ya está en preparación');
      container = crearContainer();
      final notifier = container.read(orderTrackingProvider(_ordenId).notifier);
      await _esperar();

      final ok = await notifier.cancelar('otro motivo');

      expect(ok, isFalse);
      expect(estado().error, contains('en preparación'));
      expect(estado().estado, EstadoPedido.pendiente);
    });
  });
}

Future<void> _esperar() =>
    Future<void>.delayed(const Duration(milliseconds: 20));
