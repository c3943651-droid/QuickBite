import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/widgets/status_timeline.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/core/widgets/chips.dart';
import 'package:quickbite_mobile/src/features/order/presentation/estado_pedido_ui.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_tracking_providers.dart';

void main() {
  group('EstadoPedidoUi', () {
    test('cada estado tiene su propio tono semántico', () {
      final tonos = EstadoPedido.values.map((e) => e.tone).toSet();

      expect(tonos.length, greaterThan(1));
      expect(EstadoPedido.entregado.tone, StatusTone.success);
      expect(EstadoPedido.cancelado.tone, StatusTone.danger);
      expect(EstadoPedido.enCamino.tone, StatusTone.warning);
    });

    test('cada estado tiene icono', () {
      expect(EstadoPedido.values, isNotEmpty);
    });
  });

  group('pasosTimeline', () {
    test('marca completados, el actual y los que faltan', () {
      final pasos = pasosTimeline(EstadoPedido.listo);

      expect(pasos.map((p) => p.state), [
        TimelineStepState.completed,
        TimelineStepState.completed,
        TimelineStepState.completed,
        TimelineStepState.current,
        TimelineStepState.pending,
        TimelineStepState.pending,
      ]);
      expect(pasos[3].label, 'Listo');
    });

    test('el paso actual lleva la hora del último cambio', () {
      final pasos = pasosTimeline(
        EstadoPedido.enCamino,
        actualizadoEn: DateTime.utc(2026, 9, 27, 15, 10),
      );

      expect(pasos[4].timestamp, isNotNull);
      expect(pasos[4].state, TimelineStepState.current);
    });

    test('un pedido entregado cierra la línea sin paso actual', () {
      final pasos = pasosTimeline(EstadoPedido.entregado);

      expect(
        pasos.every((p) => p.state == TimelineStepState.completed),
        isTrue,
      );
      expect(
        pasos.any((p) => p.state == TimelineStepState.current),
        isFalse,
        reason: 'sin paso actual el widget no pulsa',
      );
    });

    test('un pedido cancelado deja la línea en gris', () {
      final pasos = pasosTimeline(EstadoPedido.cancelado);

      expect(pasos.every((p) => p.state == TimelineStepState.pending), isTrue);
    });

    test('cada paso tiene icono para el estado pendiente', () {
      final pasos = pasosTimeline(EstadoPedido.pendiente);

      expect(pasos, isNotEmpty);
      expect(pasos.first.label, 'Pendiente');
      expect(pasos.last.label, 'Entregado');
    });
  });
}
