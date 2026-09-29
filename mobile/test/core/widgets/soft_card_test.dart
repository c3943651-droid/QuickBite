import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_radius.dart';
import 'package:quickbite_mobile/src/core/widgets/soft_card.dart';

import '../../support/widget_harness.dart';

/// Superficies "premium": sombra difusa y borde suave en vez de una sombra dura
/// de Material por defecto, que en el Moto G15 se veía como un borde negro.
void main() {
  group('SoftCard (rediseño de superficie)', () {
    testWidgets('es blanca con borde suave y sombra difusa', (tester) async {
      await pumpApp(tester, const Scaffold(body: SoftCard(child: Text('x'))));

      // `Container` construye un `DecoratedBox` por dentro: es ahí donde vive
      // la decoración que hay que inspeccionar.
      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;

      expect(decoracion.color, AppColors.surface);
      // `Border.all` produce un `Border` uniforme: el radio vive en la
      // `borderRadius` de la caja, no en el borde.
      expect(decoracion.borderRadius, BorderRadius.circular(AppRadius.card));
      final sombra = decoracion.boxShadow!;
      expect(sombra, isNotEmpty);
      // Difusa = muchosSigma y poco desplazamiento; una sombra dura se nota como
      // un borde gris oscuro alrededor de la tarjeta.
      expect(sombra.first.spreadRadius, lessThan(0));
      expect(
        sombra.first.blurRadius,
        greaterThan(sombra.first.spreadRadius + 8),
      );
    });

    testWidgets('el borde es de 1 px del color de marca', (tester) async {
      await pumpApp(tester, const Scaffold(body: SoftCard(child: Text('x'))));

      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      final borde = decoracion.border!;
      final paint = (borde as Border).top;

      expect(paint.width, 1);
      expect(paint.color, AppColors.border);
    });

    testWidgets('admite padding propio', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: SoftCard(padding: EdgeInsets.all(24), child: Text('x')),
        ),
      );

      // `Material` mete un `Padding` propio de 1 px, así que se busca el que
      // lleva el valor pedido y no el primero de la rama.
      final padding = tester.widget<Padding>(
        find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(24),
        ),
      );
      expect(padding.padding, const EdgeInsets.all(24));
    });
  });

  group('gradiente de marca', () {
    test('el degradado va del acento a su parada profunda', () {
      expect(AppGradiente.acento.colors, [
        AppColors.accent,
        AppColors.accentDeep,
      ]);
      expect(AppGradiente.destacado.colors, [
        AppColors.accent,
        AppColors.accentAlt,
      ]);
      expect(AppGradiente.encabezado.colors.first, AppColors.ink);
    });

    testWidgets('aplicado a un botón el fondo es el degradado', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: BrandGradient(
            child: SizedBox(width: 120, child: Text('Listo')),
          ),
        ),
      );

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
  });
}
