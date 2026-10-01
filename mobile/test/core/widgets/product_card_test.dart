import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/widgets/product_card.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';

import '../../support/catalog_fakes.dart';

void main() {
  var quickAdds = 0;

  setUp(() => quickAdds = 0);

  Widget card({
    required bool disponible,
    ProductCardLayout layout = ProductCardLayout.grid,
    String? imagenUrl,
  }) => ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          // Anchos reales: la tarjeta de rejilla ocupa media pantalla y la
          // de lista el ancho completo.
          height: layout == ProductCardLayout.grid ? 260 : 100,
          width: layout == ProductCardLayout.grid ? 180 : 360,
          child: ProductCard(
            product: Product(
              id: quickbitePastor.id,
              nombre: quickbitePastor.nombre,
              precio: quickbitePastor.precio,
              categoria: quickbitePastor.categoria,
              disponible: disponible,
              imagenUrl: imagenUrl,
            ),
            onTap: () {},
            onQuickAdd: () => quickAdds++,
            layout: layout,
          ),
        ),
      ),
    ),
  );

  group('ProductCard — tarjeta del catálogo (09 §7.2, §7.3 y §8.3)', () {
    BoxDecoration decoracionTarjeta(WidgetTester tester) =>
        tester
                .widgetList<Container>(find.byType(Container))
                .firstWhere((c) => c.decoration is BoxDecoration)
                .decoration!
            as BoxDecoration;

    testWidgets('la rejilla usa radio 12 y sombra suave', (tester) async {
      await tester.pumpWidget(card(disponible: true));

      final decoracion = decoracionTarjeta(tester);
      expect(decoracion.borderRadius, BorderRadius.circular(12));
      expect(decoracion.boxShadow, isNotNull);
      expect(decoracion.boxShadow!.first.blurRadius, greaterThan(0));
    });

    testWidgets('la tarjeta de lista comparte la misma envoltura', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(disponible: true, layout: ProductCardLayout.list),
      );

      final decoracion = decoracionTarjeta(tester);
      expect(decoracion.borderRadius, BorderRadius.circular(12));
      expect(decoracion.boxShadow, isNotNull);
    });

    testWidgets('la imagen se recorta con las esquinas de la tarjeta', (
      tester,
    ) async {
      await tester.pumpWidget(card(disponible: true));

      expect(find.byType(ClipRRect), findsWidgets);
    });
  });

  group('ProductCard (07.1 SCR-CAT-01 · SCR-CAT-04)', () {
    testWidgets('un producto agotado se marca como Agotado', (tester) async {
      await tester.pumpWidget(card(disponible: false));
      await tester.pumpAndSettle();

      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('un producto disponible no muestra la marca', (tester) async {
      await tester.pumpWidget(card(disponible: true));
      await tester.pumpAndSettle();

      expect(find.text('Agotado'), findsNothing);
    });

    testWidgets('el quick-add queda bloqueado sin disponibilidad', (
      tester,
    ) async {
      await tester.pumpWidget(card(disponible: false));
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add_circle),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('el quick-add funciona con disponibilidad', (tester) async {
      await tester.pumpWidget(card(disponible: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle));
      expect(quickAdds, 1);
    });

    testWidgets('la variante de lista también marca Agotado', (tester) async {
      await tester.pumpWidget(
        card(disponible: false, layout: ProductCardLayout.list),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('una imagen relativa se resuelve contra el origen del API', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(disponible: true, imagenUrl: '/uploads/productos/pastor.jpg'),
      );

      final imagen = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(
        imagen.imageUrl,
        'https://quickbite-n1bk.onrender.com/uploads/productos/pastor.jpg',
      );
    });
  });
}
