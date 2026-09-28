import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';

const _pedidoId = '55555555-5555-5555-5555-555555555555';

Notificacion _notificacion(
  TipoNotificacion tipo, {
  bool leido = false,
  String? pedidoId,
}) => Notificacion(
  id: 'n1',
  tipo: tipo,
  titulo: 'Tu pedido cambió de estado',
  mensaje: 'Ahora está en camino.',
  pedidoId: pedidoId,
  leido: leido,
  creadoEn: DateTime(2026, 9, 27),
);

void main() {
  group('TipoNotificacion', () {
    test('el backend serializa el tipo como número', () {
      expect(TipoNotificacion.pedidoNuevo.api, 1);
      expect(TipoNotificacion.cambioEstado.api, 2);
      expect(TipoNotificacion.asignacion.api, 3);
      expect(TipoNotificacion.sistema.api, 4);
      expect(TipoNotificacion.recordatorio.api, 5);
    });

    test('desdeApi mapea los cinco tipos del backend', () {
      expect(TipoNotificacion.desdeApi(1), TipoNotificacion.pedidoNuevo);
      expect(TipoNotificacion.desdeApi(2), TipoNotificacion.cambioEstado);
      expect(TipoNotificacion.desdeApi(3), TipoNotificacion.asignacion);
      expect(TipoNotificacion.desdeApi(4), TipoNotificacion.sistema);
      expect(TipoNotificacion.desdeApi(5), TipoNotificacion.recordatorio);
    });

    test('un tipo desconocido cae en sistema sin romper la lista', () {
      expect(TipoNotificacion.desdeApi(99), TipoNotificacion.sistema);
    });

    test('los tipos de pedido se distinguen de los de sistema', () {
      expect(TipoNotificacion.pedidoNuevo.esPedido, isTrue);
      expect(TipoNotificacion.cambioEstado.esPedido, isTrue);
      expect(TipoNotificacion.asignacion.esPedido, isTrue);
      expect(TipoNotificacion.sistema.esPedido, isFalse);
      expect(TipoNotificacion.recordatorio.esPedido, isFalse);
    });

    test('cada tipo tiene etiqueta e icono', () {
      expect(TipoNotificacion.pedidoNuevo.etiqueta, isNotEmpty);
      expect(TipoNotificacion.cambioEstado.etiqueta, isNotEmpty);
      expect(TipoNotificacion.sistema.etiqueta, isNotEmpty);
    });
  });

  group('Notificacion', () {
    test('copyWith marca como leída', () {
      final leida = _notificacion(TipoNotificacion.pedidoNuevo)
          .copyWith(leido: true, leidoEn: DateTime(2026, 9, 28));

      expect(leida.leido, isTrue);
      expect(leida.leidoEn, isNotNull);
      expect(leida.titulo, 'Tu pedido cambió de estado');
    });

    test('las notificaciones de pedido conservan el pedido asociado', () {
      final conPedido = _notificacion(
        TipoNotificacion.cambioEstado,
        pedidoId: _pedidoId,
      );

      expect(conPedido.pedidoId, _pedidoId);
      expect(conPedido.tienePedido, isTrue);
    });

    test('una notificación de sistema no tiene pedido asociado', () {
      final sistema = _notificacion(TipoNotificacion.recordatorio);

      expect(sistema.tienePedido, isFalse);
      expect(sistema.pedidoId, isNull);
    });
  });

  group('FiltroNotificacion', () {
    test('los cuatro filtros tienen etiqueta', () {
      expect(FiltroNotificacion.todas.etiqueta, 'Todas');
      expect(FiltroNotificacion.noLeidas.etiqueta, 'No leídas');
      expect(FiltroNotificacion.pedidos.etiqueta, 'Pedidos');
      expect(FiltroNotificacion.sistema.etiqueta, 'Sistema');
    });

    test('todas incluye cualquier notificación', () {
      expect(
        FiltroNotificacion.todas.incluye(
          _notificacion(TipoNotificacion.sistema),
        ),
        isTrue,
      );
    });

    test('noLeidas solo incluye las no leídas', () {
      final noLeida = _notificacion(TipoNotificacion.pedidoNuevo);
      final leida = _notificacion(TipoNotificacion.pedidoNuevo, leido: true);

      expect(FiltroNotificacion.noLeidas.incluye(noLeida), isTrue);
      expect(FiltroNotificacion.noLeidas.incluye(leida), isFalse);
    });

    test('pedidos solo incluye los tipos de pedido', () {
      expect(
        FiltroNotificacion.pedidos.incluye(
          _notificacion(TipoNotificacion.asignacion, pedidoId: _pedidoId),
        ),
        isTrue,
      );
      expect(
        FiltroNotificacion.pedidos.incluye(
          _notificacion(TipoNotificacion.sistema),
        ),
        isFalse,
      );
    });

    test('sistema solo incluye los tipos de sistema', () {
      expect(
        FiltroNotificacion.sistema.incluye(
          _notificacion(TipoNotificacion.recordatorio),
        ),
        isTrue,
      );
      expect(
        FiltroNotificacion.sistema.incluye(
          _notificacion(TipoNotificacion.pedidoNuevo),
        ),
        isFalse,
      );
    });
  });
}
