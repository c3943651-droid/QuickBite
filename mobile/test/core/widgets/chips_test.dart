import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';
import 'package:quickbite_mobile/src/core/widgets/chips.dart';

import '../../support/widget_harness.dart';

/// El fondo de cada chip: Container/DecoratedBox con el color de fondo.
Color backgroundOf(WidgetTester tester) {
  final containers = tester
      .widgetList<Container>(find.byType(Container))
      .where((c) => c.color != null)
      .toList();
  return containers.first.color!;
}

TextStyle labelStyleOf(WidgetTester tester, [String label = 'Pendiente']) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  group('StatusChip (09 §8.4)', () {
    testWidgets('sin tono explícito usa el tono neutro', (tester) async {
      await pumpApp(tester, const StatusChip(label: 'Pendiente'));

      expect(find.text('Pendiente'), findsOneWidget);
      expect(labelStyleOf(tester).color, AppColors.textGray);
    });

    testWidgets('el fondo es el color del tono al 20 % de opacidad', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const StatusChip(label: 'Pendiente', tone: StatusTone.info),
      );

      expect(backgroundOf(tester), AppColors.infoBlue.withValues(alpha: 0.2));
    });

    testWidgets('cada tono usa su color semántico', (tester) async {
      const casos = {
        StatusTone.neutral: AppColors.textGray,
        StatusTone.info: AppColors.infoBlue,
        StatusTone.progress: AppColors.warningYellow,
        StatusTone.warning: AppColors.errorRed,
        StatusTone.success: AppColors.successGreen,
        StatusTone.danger: AppColors.appetiteRed,
      };

      for (final entry in casos.entries) {
        await pumpApp(tester, StatusChip(label: 'X', tone: entry.key));
        expect(
          labelStyleOf(tester, 'X').color,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('el icono es opcional', (tester) async {
      await pumpApp(tester, const StatusChip(label: 'Listo'));
      expect(find.byIcon(Icons.check), findsNothing);

      await pumpApp(
        tester,
        const StatusChip(label: 'Listo', icon: Icons.check),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('respeta el tema oscuro', (tester) async {
      await pumpApp(
        tester,
        const StatusChip(label: 'Entregado', tone: StatusTone.success),
        theme: AppTheme.dark,
      );

      expect(find.text('Entregado'), findsOneWidget);
      expect(labelStyleOf(tester, 'Entregado').color, AppColors.successGreen);
    });
  });

  group('CategoryChip (09 §8.4)', () {
    testWidgets('inactivo: fondo gris claro y texto gris', (tester) async {
      await pumpApp(
        tester,
        CategoryChip(label: 'Burgers', selected: false, onTap: () {}),
      );

      expect(backgroundOf(tester), AppColors.mistGray);
      expect(
        tester.widget<Text>(find.text('Burgers')).style?.color,
        AppColors.textGray,
      );
    });

    testWidgets('activo: fondo naranja y texto blanco', (tester) async {
      await pumpApp(
        tester,
        CategoryChip(label: 'Burgers', selected: true, onTap: () {}),
      );

      expect(backgroundOf(tester), AppColors.quickbiteOrange);
      expect(
        tester.widget<Text>(find.text('Burgers')).style?.color,
        AppColors.white,
      );
    });

    testWidgets('avisa del toque', (tester) async {
      var toques = 0;
      await pumpApp(
        tester,
        CategoryChip(label: 'Burgers', selected: false, onTap: () => toques++),
      );

      await tester.tap(find.text('Burgers'));
      await tester.pump();

      expect(toques, 1);
    });
  });
}
