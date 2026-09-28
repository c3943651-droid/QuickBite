import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/widgets/polling_indicator.dart';

import '../../support/widget_harness.dart';

void main() {
  group('PollingIndicator (09 §8.6)', () {
    testWidgets('no ocupa espacio cuando no está actualizando', (tester) async {
      await pumpApp(
        tester,
        const Column(
          children: [PollingIndicator(active: false), Text('debajo')],
        ),
      );

      expect(find.text('Actualizando...'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('muestra "Actualizando..." sin bloquear la pantalla', (
      tester,
    ) async {
      await pumpApp(tester, const PollingIndicator(active: true));

      expect(find.text('Actualizando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('no es intrusivo: es un indicador pequeño, no un bloque', (
      tester,
    ) async {
      await pumpApp(tester, const PollingIndicator(active: true));

      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.strokeWidth, lessThanOrEqualTo(2));
    });

    testWidgets('cambia de visible a oculto sin reubicar el contenido', (
      tester,
    ) async {
      await pumpApp(tester, const PollingIndicator(active: true));
      expect(find.text('Actualizando...'), findsOneWidget);

      await pumpApp(tester, const PollingIndicator(active: false));
      await tester.pump();

      expect(find.text('Actualizando...'), findsNothing);
    });

    testWidgets('admite un texto propio', (tester) async {
      await pumpApp(
        tester,
        const PollingIndicator(active: true, label: 'Buscando repartidores'),
      );

      expect(find.text('Buscando repartidores'), findsOneWidget);
    });
  });
}
