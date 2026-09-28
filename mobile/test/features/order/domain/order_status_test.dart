import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

void main() {
  group('EstadoPedido', () {
    test('traduce el estado que devuelve la API', () {
      expect(EstadoPedido.fromApi('Pendiente'), EstadoPedido.pendiente);
      expect(EstadoPedido.fromApi('enCamino'), EstadoPedido.enCamino);
      expect(EstadoPedido.fromApi('Entregado'), EstadoPedido.entregado);
    });

    test('un estado desconocido se lee como pendiente', () {
      expect(EstadoPedido.fromApi('Algo raro'), EstadoPedido.pendiente);
    });

    test('la línea de tiempo son los seis estados en orden', () {
      expect(EstadoPedido.linea, [
        EstadoPedido.pendiente,
        EstadoPedido.confirmado,
        EstadoPedido.preparando,
        EstadoPedido.listo,
        EstadoPedido.enCamino,
        EstadoPedido.entregado,
      ]);
    });

    test('los estados en curso son los que aún se mueven', () {
      expect(EstadoPedido.pendiente.esActivo, isTrue);
      expect(EstadoPedido.confirmado.esActivo, isTrue);
      expect(EstadoPedido.preparando.esActivo, isTrue);
      expect(EstadoPedido.listo.esActivo, isTrue);
      expect(EstadoPedido.enCamino.esActivo, isTrue);
      expect(EstadoPedido.entregado.esActivo, isFalse);
      expect(EstadoPedido.cancelado.esActivo, isFalse);
    });

    test('solo se puede cancelar mientras está pendiente o confirmado', () {
      expect(EstadoPedido.pendiente.esCancelable, isTrue);
      expect(EstadoPedido.confirmado.esCancelable, isTrue);
      expect(EstadoPedido.preparando.esCancelable, isFalse);
      expect(EstadoPedido.enCamino.esCancelable, isFalse);
      expect(EstadoPedido.entregado.esCancelable, isFalse);
      expect(EstadoPedido.cancelado.esCancelable, isFalse);
    });

    test('el estado actual marca su posición en la línea de tiempo', () {
      expect(EstadoPedido.pendiente.indiceEnLinea, 0);
      expect(EstadoPedido.listo.indiceEnLinea, 3);
      expect(EstadoPedido.entregado.indiceEnLinea, 5);
      expect(EstadoPedido.cancelado.indiceEnLinea, -1);
    });

    test('los estados terminales son entregado y cancelado', () {
      expect(EstadoPedido.entregado.esFinal, isTrue);
      expect(EstadoPedido.cancelado.esFinal, isTrue);
      expect(EstadoPedido.enCamino.esFinal, isFalse);
    });

    test('la etiqueta es legible para la persona usuaria', () {
      expect(EstadoPedido.enCamino.etiqueta, 'En camino');
      expect(EstadoPedido.pendiente.etiqueta, 'Pendiente');
    });

    test('los filtros del historial agrupan los estados', () {
      expect(FiltroPedido.todos.estados, isEmpty);
      expect(FiltroPedido.pendientes.estados, [EstadoPedido.pendiente]);
      expect(FiltroPedido.enCurso.estados, [
        EstadoPedido.pendiente,
        EstadoPedido.confirmado,
        EstadoPedido.preparando,
        EstadoPedido.listo,
        EstadoPedido.enCamino,
      ]);
      expect(FiltroPedido.entregados.estados, [EstadoPedido.entregado]);
      expect(FiltroPedido.cancelados.estados, [EstadoPedido.cancelado]);
    });

    test('los filtros del historial llevan su etiqueta', () {
      expect(FiltroPedido.values.map((f) => f.etiqueta), [
        'Todos',
        'Pendientes',
        'En curso',
        'Entregados',
        'Cancelados',
      ]);
    });
  });
}
