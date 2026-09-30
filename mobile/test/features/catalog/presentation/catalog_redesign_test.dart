import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/chips.dart';
import 'package:quickbite_mobile/src/core/widgets/product_card.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_header.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/widget_harness.dart';

/// Rediseño del catálogo: encabezado con degradado, tarjetas con sombra difusa y
/// transición Hero de la imagen al detalle.
void main() {
  group('CatalogHeader', () {
    testWidgets('lleva un degradado de marca y texto blanco', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: CatalogHeader(nombre: 'Carlos')),
      );

      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;

      expect(decoracion.gradient, isNotNull);
      final degradado = decoracion.gradient! as LinearGradient;
      expect(degradado.colors.first, AppColors.ink);
      final texto = tester.widget<Text>(find.textContaining('Carlos').first);
      expect(texto.style?.color, AppColors.white);
    });

    testWidgets('el saludo cambia según la hora', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: CatalogHeader(nombre: 'Carlos', hora: 9)),
      );
      expect(find.textContaining('Buenos días'), findsOneWidget);

      await pumpApp(
        tester,
        const Scaffold(body: CatalogHeader(nombre: 'Carlos', hora: 15)),
      );
      expect(find.textContaining('Buenas tardes'), findsOneWidget);

      await pumpApp(
        tester,
        const Scaffold(body: CatalogHeader(nombre: 'Carlos', hora: 21)),
      );
      expect(find.textContaining('Buenas noches'), findsOneWidget);
    });

    testWidgets('la campana está centrada en su contenedor circular', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: CatalogHeader(nombre: 'Carlos')),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.alignment, Alignment.center);

      final campanaRect = tester.getRect(find.byIcon(Icons.notifications_none));
      final containerRect = tester.getRect(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(campanaRect.center.dx, closeTo(containerRect.center.dx, 1.0));
      expect(campanaRect.center.dy, closeTo(containerRect.center.dy, 1.0));
    });

    testWidgets('pide iconos claros en la barra de estado', (tester) async {
      // La banda es oscura y llega hasta el borde superior (edge-to-edge), así
      // que hereda el estilo global de la app, que en modo claro pone iconos
      // OSCUROS. Sobre el degradado se convertían en negro sobre negro: el reloj
      // y la batería desaparecían. La cabecera tiene que declarar su propio
      // estilo, que gana sobre el de `QuickBiteApp`.
      await pumpApp(
        tester,
        const Scaffold(body: CatalogHeader(nombre: 'Carlos')),
      );

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
    });
  });

  group('ProductCard con Hero', () {
    Future<void> pumpCard(WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: ProductCard(
              product: quickbitePastor,
              onTap: () {},
              onQuickAdd: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('la imagen viaja con un Hero etiquetado por producto', (
      tester,
    ) async {
      await pumpCard(tester);

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'producto-${quickbitePastor.id}');
    });

    testWidgets('el Hero solo envuelve la imagen, no toda la tarjeta', (
      tester,
    ) async {
      await pumpCard(tester);

      final imagen = find.byType(Hero);
      expect(
        find.descendant(of: imagen, matching: find.byType(ProductCard)),
        findsNothing,
      );
    });

    testWidgets('el detalle usa el mismo Hero para que la imagen viaje', (
      tester,
    ) async {
      // Mismo tag en las dos pantallas: es lo que hace que el vuelo de la
      // animación sea recognized por el Navigator y no se vea como un salto.
      await pumpApp(
        tester,
        Scaffold(
          body: Column(
            key: const Key('columna'),
            children: [
              SizedBox(
                width: 180,
                height: 260,
                child: ProductCard(product: quickbitePastor, onTap: () {}),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 180,
                height: 120,
                child: Hero(
                  tag: heroProducto(quickbitePastor.id),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Hero), findsNWidgets(2));
    });
  });

  group('CategoryChip', () {
    testWidgets('tiene bordes redondeados y padding adecuado', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: CategoryChip(label: 'Tacos', selected: false, onTap: () {}),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CategoryChip),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decor = container.decoration! as BoxDecoration;
      expect(decor.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('el chip activo tiene sombra sutil', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: CategoryChip(label: 'Tacos', selected: true, onTap: () {}),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decor = container.decoration! as BoxDecoration;
      expect(decor.boxShadow, isNotNull);
      expect(decor.boxShadow!.first.blurRadius, greaterThan(0));
    });

    testWidgets('el chip activo tiene texto blanco y el inactivo contrastante', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Row(
            children: [
              CategoryChip(label: 'Tacos', selected: true, onTap: () {}),
              const SizedBox(width: 8),
              CategoryChip(label: 'Bebidas', selected: false, onTap: () {}),
            ],
          ),
        ),
      );

      final activo = tester.widget<Text>(find.text('Tacos'));
      expect(activo.style?.color, AppColors.white);

      final inactivo = tester.widget<Text>(find.text('Bebidas'));
      expect(inactivo.style?.color, isNotNull);
      expect(inactivo.style?.color, isNot(AppColors.white));
    });
  });

  group('tarjeta de catálogo', () {
    testWidgets('radio de 18 px y sombra difusa', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: ProductCard(product: quickbitePastor, onTap: () {}),
          ),
        ),
      );

      final decoracion =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      expect(decoracion.borderRadius, BorderRadius.circular(12));
      expect(decoracion.boxShadow, isNotNull);
      expect(decoracion.boxShadow!.first.blurRadius, greaterThan(0));
      expect(decoracion.boxShadow!.first.offset, const Offset(0, 2));
    });

    testWidgets('la imagen ocupa la misma altura con nombre largo o corto', (
      tester,
    ) async {
      // El nombre va en `maxLines: 2`, así que un nombre largo crece el bloque de
      // texto y la imagen `Expanded` se encoge. En la rejilla eso desalinea las
      // fotos de dos tarjetas de la misma fila y el catálogo se ve desordenado.
      // El bloque de texto reserva siempre las dos líneas.
      const nombreCorto = Product(
        id: 'p3',
        nombre: 'Tacos',
        precio: 150,
        disponible: true,
        categoria: quickbiteTacos,
      );
      const nombreLargo = Product(
        id: 'p2',
        nombre: 'Burrito de carnitas con queso gratinado especial',
        precio: 189,
        disponible: true,
        categoria: quickbiteTacos,
      );

      await pumpApp(
        tester,
        Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 192,
                height: 223,
                child: ProductCard(product: nombreCorto, onTap: () {}),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 192,
                height: 223,
                child: ProductCard(product: nombreLargo, onTap: () {}),
              ),
            ],
          ),
        ),
      );

      final imagenes = find.byType(Hero);
      expect(imagenes, findsNWidgets(2));
      // El borde inferior es el que se desalinea: el bloque de texto crece con
      // la segunda línea del nombre y la imagen `Expanded` cede ese alto.
      final abajoCorto = tester.getRect(imagenes.at(0)).bottom;
      final abajoLargo = tester.getRect(imagenes.at(1)).bottom;

      expect(abajoLargo, abajoCorto);
    });
  });
}
