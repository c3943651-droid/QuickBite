import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/primary_button.dart';
import 'package:quickbite_mobile/src/core/widgets/soft_card.dart';

import '../../support/widget_harness.dart';

/// El botón primario es la acción más repetida de la app (agregar al carrito,
/// confirmar pedido, aceptar entrega). Con un color plano se leía como un
/// rectángulo más; el degradado le da la profundidad que el resto del rediseño
/// busca, sin dejar de ser un botón real con ripple y foco de teclado.
void main() {
  Future<void> pumpBoton(
    WidgetTester tester, {
    bool cargado = false,
    bool deshabilitado = false,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: PrimaryButton(
          label: 'Agregar al carrito',
          icon: Icons.add,
          isLoading: cargado,
          onPressed: deshabilitado ? null : () {},
        ),
      ),
    );
  }

  group('PrimaryButton con degradado de marca', () {
    testWidgets('el fondo es el degradante del acento', (tester) async {
      await pumpBoton(tester);

      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;

      expect(decoracion.gradient, isA<LinearGradient>());
      expect((decoracion.gradient as LinearGradient).colors, [
        AppColors.accent,
        AppColors.accentDeep,
      ]);
    });

    testWidgets('sigue siendo un FilledButton con su etiqueta', (tester) async {
      await pumpBoton(tester);

      // Se conserva el widget base de Material a propósito: los 20+ tests que
      // buscan `FilledButton` por etiqueta siguen siendo válidos.
      expect(
        find.widgetWithText(FilledButton, 'Agregar al carrito'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('el texto y el icono van en blanco sobre el degradado', (
      tester,
    ) async {
      await pumpBoton(tester);

      final boton = tester.widget<FilledButton>(find.byType(FilledButton));
      final estilo = boton.style!;
      expect(estilo.backgroundColor?.resolve({}), Colors.transparent);
      expect(estilo.foregroundColor?.resolve({}), Colors.white);
    });

    testWidgets('cargando muestra el spinner sin perder el degradado', (
      tester,
    ) async {
      await pumpBoton(tester, cargado: true);

      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      expect(decoracion.gradient, isNotNull);
    });

    testWidgets('deshabilitado apaga el degradado sin perder la forma', (
      tester,
    ) async {
      await pumpBoton(tester, deshabilitado: true);

      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      final degradado = decoracion.gradient as LinearGradient;

      // Sigue having una rampa, pero en grises: quitar el degradado a secas
      // dejaba el botón sin forma, y reutilizar el de marca hacía que un botón
      // deshabilitado siguiera gritando "pulsa aquí".
      expect(degradado.colors, isNot(AppGradiente.acento.colors));
      expect(degradado.colors.first, AppColors.surfaceMuted);
      expect(decoracion.boxShadow, isNull);
    });
  });

  group('SecondaryButton', () {
    testWidgets('es una superficie blanca con borde de marca', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SecondaryButton(label: 'Volver', onPressed: () {}),
        ),
      );

      final boton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final estilo = boton.style!;
      final lado = estilo.side!.resolve({})!;
      expect(lado.color, AppColors.accent);
    });
  });
}
