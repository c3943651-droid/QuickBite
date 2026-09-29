import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_radius.dart';
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
      expect(decoracion.borderRadius, BorderRadius.circular(AppRadius.card));
      expect(decoracion.boxShadow, isNotNull);
      expect(decoracion.boxShadow!.first.blurRadius, greaterThan(10));
      expect(decoracion.boxShadow!.first.spreadRadius, lessThan(0));
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
