import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/estadisticas_repartidor.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

void main() {
  group('PedidoEntrega (07.1 SCR-DEL-01/02)', () {
    test('guarda lo que devuelve GET /delivery/available', () {
      final pedido = PedidoEntrega(
        id: 'o1',
        numeroPedido: 'QB-001',
        estado: 'listo',
        total: 250.5,
        creadoEn: DateTime.utc(2026, 9, 28, 18),
      );

      expect(pedido.id, 'o1');
      expect(pedido.numeroPedido, 'QB-001');
      expect(pedido.estado, 'listo');
      expect(pedido.total, 250.5);
    });

    test('expone el estado tipado del pedido', () {
      expect(
        PedidoEntrega(
          id: 'o1',
          numeroPedido: 'QB-001',
          estado: 'listo',
          total: 1,
        ).estadoPedido,
        EstadoPedido.listo,
      );
      expect(
        PedidoEntrega(
          id: 'o1',
          numeroPedido: 'QB-001',
          estado: 'EnCamino',
          total: 1,
        ).estadoPedido,
        EstadoPedido.enCamino,
      );
    });

    test('solo un pedido listo se puede aceptar', () {
      PedidoEntrega construir(String estado) =>
          PedidoEntrega(id: 'o1', numeroPedido: 'QB-001', estado: estado, total: 1);

      expect(construir('listo').sePuedeAceptar, isTrue);
      expect(construir('en_camino').sePuedeAceptar, isFalse);
      expect(construir('entregado').sePuedeAceptar, isFalse);
      expect(construir('cancelado').sePuedeAceptar, isFalse);
    });

    test('un pedido sin fecha de creación no rompe el cálculo de edad', () {
      final pedido = PedidoEntrega(
        id: 'o1',
        numeroPedido: 'QB-001',
        estado: 'listo',
        total: 1,
      );

      expect(pedido.creadoEn, isNull);
      expect(pedido.minutosDesdeCreacion(DateTime.utc(2026, 9, 28)), isNull);
    });

    test('calcula los minutos transcurridos desde que se creó', () {
      final pedido = PedidoEntrega(
        id: 'o1',
        numeroPedido: 'QB-001',
        estado: 'listo',
        total: 1,
        creadoEn: DateTime.utc(2026, 9, 28, 18),
      );

      expect(pedido.minutosDesdeCreacion(DateTime.utc(2026, 9, 28, 18, 42)), 42);
    });

    test('un reloj anterior a la creación no da un tiempo negativo', () {
      final pedido = PedidoEntrega(
        id: 'o1',
        numeroPedido: 'QB-001',
        estado: 'listo',
        total: 1,
        creadoEn: DateTime.utc(2026, 9, 28, 18),
      );

      expect(pedido.minutosDesdeCreacion(DateTime.utc(2026, 9, 28, 17)), 0);
    });

    test('los pedidos se comparan por contenido', () {
      PedidoEntrega construir() => PedidoEntrega(
        id: 'o1',
        numeroPedido: 'QB-001',
        estado: 'listo',
        total: 250.5,
      );

      expect(construir(), construir());
      expect(construir().hashCode, construir().hashCode);
    });
  });

  group('EstadisticasRepartidor (07.1 SCR-DEL-06)', () {
    test('guarda las cinco métricas de GET /delivery/stats', () {
      final stats = EstadisticasRepartidor(
        entregasTotales: 12,
        entregasDelMes: 3,
        tiempoPromedioEntregaMinutos: 27.5,
        pedidosAsignados: 15,
        cancelaciones: 1,
      );

      expect(stats.entregasTotales, 12);
      expect(stats.entregasDelMes, 3);
      expect(stats.tiempoPromedioEntregaMinutos, 27.5);
      expect(stats.pedidosAsignados, 15);
      expect(stats.cancelaciones, 1);
    });

    test('un repartidor sin entregas ve ceros, no una pantalla vacía', () {
      const stats = EstadisticasRepartidor.vacias();

      expect(stats.entregasTotales, 0);
      expect(stats.entregasDelMes, 0);
      expect(stats.tiempoPromedioEntregaMinutos, 0);
      expect(stats.pedidosAsignados, 0);
      expect(stats.cancelaciones, 0);
      expect(stats.estaVacia, isTrue);
    });

    test('con una entrega ya no se considera vacía', () {
      const stats = EstadisticasRepartidor(
        entregasTotales: 1,
        entregasDelMes: 1,
        tiempoPromedioEntregaMinutos: 0,
        pedidosAsignados: 1,
        cancelaciones: 0,
      );

      expect(stats.estaVacia, isFalse);
    });
  });
}
