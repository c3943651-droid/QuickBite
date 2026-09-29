import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_radius.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';
import 'package:quickbite_mobile/src/core/widgets/chips.dart';

import '../../support/widget_harness.dart';

/// Decoración del chip de categoría: vive en un `AnimatedContainer`.
BoxDecoration chipDecoration(WidgetTester tester) {
  final animated = tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .first;
  return animated.decoration! as BoxDecoration;
}

TextStyle labelStyleOf(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

/// Ratio de contraste WCAG 2.1 entre dos colores opacos: (L1+0.05)/(L2+0.05).
double contraste(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  group('StatusChip (09 §8.4)', () {
    testWidgets('sin tono explícito usa el tono neutro', (tester) async {
      await pumpApp(tester, const StatusChip(label: 'Pendiente'));

      expect(find.text('Pendiente'), findsOneWidget);
      expect(labelStyleOf(tester, 'Pendiente').color, isNotNull);
    });

    testWidgets('el fondo es el color del tono al 20 % de opacidad', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const StatusChip(label: 'Pendiente', tone: StatusTone.info),
      );

      final fondo = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) => c.color != null)
          .color;
      expect(fondo!.a, closeTo(0.2, 0.01));
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
  });

  group('CategoryChip (09 §8.4)', () {
    testWidgets('inactivo: píldora con borde y sin degradado', (
      tester,
    ) async {
      await pumpApp(
        tester,
        CategoryChip(label: 'Burgers', selected: false, onTap: () {}),
      );

      final decoracion = chipDecoration(tester);
      expect(decoracion.gradient, isNull);
      expect(decoracion.borderRadius, BorderRadius.circular(AppRadius.chip));
    });

    testWidgets('activo: degradado de marca y sin borde visible', (
      tester,
    ) async {
      await pumpApp(
        tester,
        CategoryChip(label: 'Burgers', selected: true, onTap: () {}),
      );

      final decoracion = chipDecoration(tester);
      expect(decoracion.gradient, isA<LinearGradient>());
      expect((decoracion.border! as Border).top.color, Colors.transparent);
    });

    testWidgets('el chip activo se anuncia como seleccionado', (tester) async {
      await pumpApp(
        tester,
        CategoryChip(label: 'Burgers', selected: true, onTap: () {}),
      );

      expect(
        tester.getSemantics(find.text('Burgers')).flagsCollection.isSelected,
        Tristate.isTrue,
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

  // Regresión del Moto G15: leída a pleno sol, la píldora inactiva era
  // invisible en modo oscuro (texto oscuro sobre píldora oscura, 0.2:1) y en
  // modo claro el texto competía con el fondo. El texto inactivo tiene que
  // seguir al tema, no a un color fijo.
  group('CategoryChip: contraste del texto inactivo (WCAG AA)', () {
    for (final oscuro in [false, true]) {
      final nombre = oscuro ? 'modo oscuro' : 'modo claro';

      testWidgets('$nombre: el texto inactivo alcanza 4.5:1 con su píldora', (
        tester,
      ) async {
        await pumpApp(
          tester,
          CategoryChip(label: 'Burgers', selected: false, onTap: () {}),
          theme: oscuro ? AppTheme.dark : AppTheme.light,
        );

        final decoracion = chipDecoration(tester);
        final fondo = decoracion.color!;
        final texto = labelStyleOf(tester, 'Burgers').color!;

        expect(
          contraste(texto, fondo),
          greaterThanOrEqualTo(4.5),
          reason:
              'texto #${texto.toARGB32().toRadixString(16)} sobre fondo '
              '#${fondo.toARGB32().toRadixString(16)}',
        );
      });

      testWidgets('$nombre: la píldora inactiva tiene borde visible', (
        tester,
      ) async {
        await pumpApp(
          tester,
          CategoryChip(label: 'Burgers', selected: false, onTap: () {}),
          theme: oscuro ? AppTheme.dark : AppTheme.light,
        );

        // El relleno de una píldora inactiva está por diseño muy cerca del fondo:
        // lo que la recorta es el borde, así que tiene que existir y notarse.
        // El umbral es bajo a propósito (la paleta usa bordes suaves, ~1.2:1);
        // lo que se rechaza es el borde transparente o fundido con el relleno,
        // que es lo que hace la píldora ilegible.
        final decoracion = chipDecoration(tester);
        final borde = (decoracion.border! as Border).top.color;
        final fondoChip = decoracion.color!;

        expect(borde, isNot(Colors.transparent));
        expect(
          contraste(borde, fondoChip),
          greaterThanOrEqualTo(1.15),
          reason: 'el borde debe recortar la píldora contra su propio fondo',
        );
      });

      testWidgets('$nombre: el borde de la píldora sigue al tema', (
        tester,
      ) async {
        await pumpApp(
          tester,
          CategoryChip(label: 'Burgers', selected: false, onTap: () {}),
          theme: oscuro ? AppTheme.dark : AppTheme.light,
        );

        final borde = (chipDecoration(tester).border! as Border).top.color;

        // Un borde claro fijo sobre superficie oscura delata el forgot de mirar
        // el tema; uno oscuro sobre superficie clara, lo mismo al revés.
        expect(
          ThemeData.estimateBrightnessForColor(borde),
          oscuro ? Brightness.dark : Brightness.light,
        );
      });
    }
  });
}
