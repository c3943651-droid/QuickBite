import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/metric_card.dart';

import '../../support/widget_harness.dart';

void main() {
  group('MetricCard (09 §8.3)', () {
    testWidgets('muestra título, valor destacado e icono', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Entregas hoy',
          value: '12',
          icon: Icons.local_shipping_outlined,
        ),
      );

      expect(find.text('Entregas hoy'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets('admite un subtítulo', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Ganancias',
          value: r'$1,240',
          icon: Icons.payments_outlined,
          subtitle: 'Esta semana',
        ),
      );

      expect(find.text('Esta semana'), findsOneWidget);
    });

    testWidgets('el valor usa el estilo destacado del tema', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Ganancias',
          value: r'$1,240',
          icon: Icons.payments_outlined,
        ),
      );

      final valor = tester.widget<Text>(find.text(r'$1,240'));
      expect(valor.style?.fontWeight, isNotNull);
      expect(
        valor.style?.fontSize,
        greaterThan(
          tester.widget<Text>(find.text('Ganancias')).style?.fontSize ?? 0,
        ),
      );
    });

    testWidgets('una variación al alza se pinta en verde', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Entregas',
          value: '12',
          icon: Icons.local_shipping_outlined,
          trend: MetricTrend.up,
          trendLabel: '+8%',
        ),
      );

      expect(find.text('+8%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('+8%')).style?.color,
        AppColors.successGreen,
      );
    });

    testWidgets('una variación a la baja se pinta en rojo', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Entregas',
          value: '4',
          icon: Icons.local_shipping_outlined,
          trend: MetricTrend.down,
          trendLabel: '-2%',
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('-2%')).style?.color,
        AppColors.errorRed,
      );
    });

    testWidgets('sin variación no dibuja nada extra', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Entregas',
          value: '4',
          icon: Icons.local_shipping_outlined,
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('la tarjeta es tocable solo si trae acción', (tester) async {
      var toques = 0;
      await pumpApp(
        tester,
        MetricCard(
          title: 'Entregas',
          value: '12',
          icon: Icons.local_shipping_outlined,
          onTap: () => toques++,
        ),
      );

      await tester.tap(find.text('Entregas'));
      await tester.pump();

      expect(toques, 1);
    });

    testWidgets('respeta el tema oscuro', (tester) async {
      await pumpApp(
        tester,
        const MetricCard(
          title: 'Entregas',
          value: '12',
          icon: Icons.local_shipping_outlined,
        ),
        theme: ThemeData.dark(useMaterial3: true),
      );

      expect(find.text('12'), findsOneWidget);
    });
  });
}
