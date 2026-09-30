import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

void main() {
  group('Order', () {
    test('guarda número, estado, totales y dirección', () {
      const order = Order(
        id: 'o1',
        numeroPedido: 'QB-20260927-AB12CD',
        estado: 'Pendiente',
        total: 216,
        direccionEntrega: 'Av. Reforma 222, Centro',
        items: [OrderItem(nombre: 'Tacos al pastor', cantidad: 2)],
      );

      expect(order.numeroPedido, 'QB-20260927-AB12CD');
      expect(order.total, 216);
      expect(order.direccionEntrega, 'Av. Reforma 222, Centro');
      expect(order.items.single.nombre, 'Tacos al pastor');
    });

    test(
      'el tiempo estimado es el que fija la app mientras la API no lo manda',
      () {
        const order = Order(
          id: 'o1',
          numeroPedido: 'QB-1',
          estado: 'Pendiente',
          total: 100,
          direccionEntrega: 'Centro',
          items: [],
        );

        expect(
          order.tiempoEntregaEstimado,
          Order.tiempoEntregaEstimadoPorDefecto,
        );
        expect(order.tiempoEntregaEstimado, greaterThan(0));
      },
    );

    test('el resumen suma los items y la cantidad total', () {
      const order = Order(
        id: 'o1',
        numeroPedido: 'QB-1',
        estado: 'Pendiente',
        total: 300,
        direccionEntrega: 'Centro',
        items: [
          OrderItem(nombre: 'Tacos', cantidad: 2),
          OrderItem(nombre: 'Refresco', cantidad: 1),
        ],
      );

      expect(order.cantidadItems, 3);
    });
  });

  group('MetodoPago', () {
    test('el valor por defecto es efectivo contra entrega', () {
      expect(MetodoPago.efectivo.api, 'efectivo');
      expect(MetodoPago.efectivo.etiqueta, 'Efectivo contra entrega');
    });

    test('tarjeta se marca como simulada', () {
      expect(MetodoPago.tarjeta.api, 'tarjeta');
      expect(MetodoPago.tarjeta.etiqueta, contains('simulad'));
    });

    test('el backend solo acepta efectivo y tarjeta', () {
      expect(MetodoPago.values.map((m) => m.api), ['efectivo', 'tarjeta']);
    });

    test('traduce el valor de la API', () {
      expect(MetodoPago.fromApi('TARJETA'), MetodoPago.tarjeta);
      expect(MetodoPago.fromApi('efectivo'), MetodoPago.efectivo);
    });
  });
}
