import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/status_timeline.dart';

import '../../support/widget_harness.dart';

/// Los seis estados que 07.1 §SCR-ORDER-01 exige en el seguimiento de un
/// pedido. El componente es agnóstico al dominio: la feature de pedidos
/// traduce su enumerado a estos pasos.
List<TimelineStep> ordenSteps({
  int? current = 3,
  int completed = 3,
  TimelineStepState? cancelado,
}) {
  const catalogo = [
    ('Pendiente', Icons.receipt_long_outlined),
    ('Confirmado', Icons.thumb_up_outlined),
    ('Preparando', Icons.local_fire_department_outlined),
    ('Listo', Icons.takeout_dining_outlined),
    ('En camino', Icons.delivery_dining_outlined),
    ('Entregado', Icons.check_circle_outline),
  ];

  return [
    for (var i = 0; i < catalogo.length; i++)
      TimelineStep(
        label: catalogo[i].$1,
        icon: catalogo[i].$2,
        timestamp: '10:0$i',
        state: i < completed
            ? TimelineStepState.completed
            : i == current
            ? TimelineStepState.current
            : TimelineStepState.pending,
      ),
    if (cancelado != null)
      TimelineStep(
        label: 'Cancelado',
        icon: Icons.cancel_outlined,
        timestamp: '10:30',
        state: cancelado,
      ),
  ];
}

/// El `Scaffold` también lleva un `ScaleTransition` interno (el del FAB), así
/// que el pulso se busca dentro del timeline.
Finder pulsoEnTimeline() => find.descendant(
  of: find.byType(StatusTimeline),
  matching: find.byType(ScaleTransition),
);

void main() {
  group('StatusTimeline (09 §8.12 y 07.1 SCR-ORDER-01)', () {
    testWidgets('renderiza los seis estados del pedido', (tester) async {
      await pumpApp(tester, StatusTimeline(steps: ordenSteps()));

      for (final etiqueta in [
        'Pendiente',
        'Confirmado',
        'Preparando',
        'Listo',
        'En camino',
        'Entregado',
      ]) {
        expect(find.text(etiqueta), findsOneWidget, reason: etiqueta);
      }
    });

    testWidgets('los pasos completados se marcan con un check', (tester) async {
      await pumpApp(
        tester,
        StatusTimeline(steps: ordenSteps(current: 3, completed: 3)),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });

    testWidgets('el paso actual se distingue de los futuros', (tester) async {
      await pumpApp(tester, StatusTimeline(steps: ordenSteps(current: 3)));

      expect(find.byKey(const ValueKey('timeline-current')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('timeline-pending-Listo')),
        findsNothing,
      );
    });

    testWidgets('el paso actual late con un pulso', (tester) async {
      await pumpApp(tester, StatusTimeline(steps: ordenSteps(current: 3)));

      final pulso = tester.widget<ScaleTransition>(pulsoEnTimeline());
      final antes = pulso.scale.value;
      await tester.pump(const Duration(milliseconds: 250));
      final despues = tester
          .widget<ScaleTransition>(pulsoEnTimeline())
          .scale
          .value;

      expect(antes, isNot(despues));
    });

    testWidgets('los pasos futuros salen atenuados', (tester) async {
      await pumpApp(
        tester,
        StatusTimeline(steps: ordenSteps(current: 2, completed: 2)),
      );

      final iconos = tester
          .widgetList<Icon>(find.byIcon(Icons.delivery_dining_outlined))
          .toList();
      expect(iconos.first.color, AppColors.inkMuted);
    });

    testWidgets('cada paso muestra su timestamp', (tester) async {
      await pumpApp(tester, StatusTimeline(steps: ordenSteps()));

      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('10:05'), findsOneWidget);
    });

    testWidgets('un pedido cancelado marca la cancelación y no avanza', (
      tester,
    ) async {
      await pumpApp(
        tester,
        StatusTimeline(
          steps: ordenSteps(
            completed: 1,
            current: null,
            cancelado: TimelineStepState.cancelled,
          ),
        ),
      );

      expect(find.text('Cancelado'), findsOneWidget);
      expect(pulsoEnTimeline(), findsNothing);
      expect(find.byKey(const ValueKey('timeline-current')), findsNothing);
    });

    testWidgets('con el pedido entregado no queda ningún paso pendiente', (
      tester,
    ) async {
      await pumpApp(
        tester,
        StatusTimeline(steps: ordenSteps(completed: 6, current: null)),
      );

      expect(find.byKey(const ValueKey('timeline-current')), findsNothing);
      expect(find.byIcon(Icons.check), findsNWidgets(6));
    });

    testWidgets('respeta el tema oscuro', (tester) async {
      await pumpApp(
        tester,
        StatusTimeline(steps: ordenSteps()),
        theme: ThemeData.dark(useMaterial3: true),
      );

      expect(find.text('Listo'), findsOneWidget);
    });
  });
}
