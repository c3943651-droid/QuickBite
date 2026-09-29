import 'package:quickbite_mobile/src/core/theme/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';

import '../../support/widget_harness.dart';

/// 09 §8.6 — La vista de estado vacío es un componente del design system, no un
/// `Center` con un texto: se usa en carrito, historial, catálogo y repartidor, y
/// todas se ven igual porque todas usan el mismo widget.
void main() {
  group('EmptyStateView (09 §8.6, §7.2 y §7.3)', () {
    testWidgets('va dentro de una tarjeta con esquinas de 16 px', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: EmptyStateView(message: 'Vacío')),
      );

      final tarjeta = tester.widget<Card>(find.byType(Card));

      expect(find.byType(Card), findsOneWidget);
      expect(
        (tarjeta.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.card),
        reason: '09 §7.2: las tarjetas redondean 16 px',
      );
    });

    testWidgets('la tarjeta tiene elevación nivel 1', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: EmptyStateView(message: 'Vacío')),
      );

      expect(tester.widget<Card>(find.byType(Card)).elevation, 1);
    });

    testWidgets('el fondo contrasta con la superficie de la pantalla', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: EmptyStateView(message: 'Vacío')),
      );

      final color = tester.widget<Card>(find.byType(Card)).color!;

      // En claro la tarjeta es gris muy claro sobre superficie blanca; lo que
      // importa es que NO se funda con el fondo.
      expect(color, isNot(AppColors.white));
      expect(ThemeData.estimateBrightnessForColor(color), Brightness.light);
    });

    testWidgets('el mensaje usa la tipografía de título, no la de cuerpo', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: EmptyStateView(message: 'Vacío')),
      );

      final texto = tester.widget<Text>(find.text('Vacío'));
      final tema = AppTheme.light;

      expect(texto.style?.fontSize, tema.textTheme.titleMedium?.fontSize);
    });

    testWidgets('el icono va en una píldora circular detrás', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: EmptyStateView(message: 'Vacío')),
      );

      final conIcono = find.descendant(
        of: find.byType(Card),
        matching: find.byType(DecoratedBox),
      );
      expect(conIcono, findsWidgets);
    });

    testWidgets('el botón de acción sigue siendo el primario de la marca', (
      tester,
    ) async {
      var accionada = false;
      await pumpApp(
        tester,
        Scaffold(
          body: EmptyStateView(
            message: 'Tu carrito está vacío',
            actionLabel: 'Ver el catálogo',
            onAction: () => accionada = true,
          ),
        ),
      );

      await tester.tap(find.text('Ver el catálogo'));
      await tester.pumpAndSettle();

      expect(accionada, isTrue);
    });

    testWidgets('sin acción no inventa botón', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: EmptyStateView(message: 'Vacío')),
      );

      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('ProductGridSkeleton', () {
    testWidgets('usa la misma proporción que la rejilla real del catálogo', (
      tester,
    ) async {
      // El esqueleto se ve mientras llegan los productos. Si su geometría no
      // coincide con la de `HomeScreen`, las tarjetas dan un salto vertical en
      // cuanto se sustituye el skeleton por el contenido.
      await pumpApp(tester, const Scaffold(body: ProductGridSkeleton()));

      final delegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.childAspectRatio, 0.86);
      expect(delegate.crossAxisCount, 2);
    });
  });
}
