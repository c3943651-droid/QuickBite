import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/estadisticas_repartidor.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/delivery_fakes.dart';

void main() {
  late FakeDeliveryRepository repository;

  setUp(() {
    repository = FakeDeliveryRepository(
      disponibles: [
        PedidoEntrega(
          id: 'o1',
          numeroPedido: 'QB-001',
          estado: EstadoPedido.listo.api,
          total: 250.5,
        ),
        PedidoEntrega(
          id: 'o2',
          numeroPedido: 'QB-002',
          estado: EstadoPedido.listo.api,
          total: 180,
        ),
      ],
    );
  });

  test('arranca con el repartidor libre y sin historial', () async {
    expect(await repository.entregaActiva(), isNull);
    expect(await repository.historialEntregas(), isEmpty);
    expect((await repository.estadisticas()).estaVacia, isTrue);
  });

  test('aceptar quita el pedido de disponibles y abre la entrega activa', () async {
    await repository.aceptar('o1');

    final disponibles = await repository.pedidosDisponibles();
    final activa = await repository.entregaActiva();

    expect(repository.aceptados, ['o1']);
    expect(disponibles.map((p) => p.id), ['o2']);
    expect(activa?.id, 'o1');
    expect(activa?.estadoPedido, EstadoPedido.enCamino);
  });

  test('completar cierra la entrega y la deja en el historial', () async {
    await repository.aceptar('o1');
    await repository.completar('o1');

    final activa = await repository.entregaActiva();
    final historial = await repository.historialEntregas();

    expect(repository.completados, ['o1']);
    expect(activa, isNull);
    expect(historial.single.id, 'o1');
    expect(historial.single.estadoPedido, EstadoPedido.entregado);
  });

  test('aceptar un pedido que no está disponible falla', () async {
    expect(() => repository.aceptar('no-existe'), throwsStateError);
  });

  test('completar sin entrega en curso falla', () async {
    expect(() => repository.completar('o1'), throwsStateError);
  });

  test('las listas devueltas no se pueden mutar desde fuera', () async {
    final disponibles = await repository.pedidosDisponibles();

    expect(() => disponibles.clear(), throwsUnsupportedError);
  });

  test('cuenta las consultas para poder observar el polling', () async {
    await repository.pedidosDisponibles();
    await repository.pedidosDisponibles();
    await repository.entregaActiva();

    expect(repository.consultasDisponibles, 2);
    expect(repository.consultasActivas, 1);
  });

  test('un error configurado se propaga en todas las lecturas', () async {
    repository.error = Exception('sin red');

    expect(() => repository.pedidosDisponibles(), throwsException);
    expect(() => repository.entregaActiva(), throwsException);
    expect(() => repository.historialEntregas(), throwsException);
    expect(() => repository.estadisticas(), throwsException);
  });

  test('aceptar y completar pueden fallar por separado', () async {
    repository.aceptarError = Exception('el pedido ya no está disponible');
    expect(() => repository.aceptar('o1'), throwsException);

    repository.aceptarError = null;
    repository.completarError = Exception('no puedes completar eso');
    await repository.aceptar('o1');
    expect(() => repository.completar('o1'), throwsException);
  });

  test('entrega las métricas configuradas', () async {
    repository.stats = const EstadisticasRepartidor(
      entregasTotales: 12,
      entregasDelMes: 3,
      tiempoPromedioEntregaMinutos: 27.5,
      pedidosAsignados: 15,
      cancelaciones: 1,
    );

    expect((await repository.estadisticas()).entregasTotales, 12);
  });
}
