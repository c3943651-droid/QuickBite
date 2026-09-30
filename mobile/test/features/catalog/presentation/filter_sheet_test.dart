import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/filter_sheet.dart';

import '../../../support/catalog_fakes.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    List<Category> categories = const [quickbiteTacos, quickbiteBebidas],
    ProductFilter initial = const ProductFilter(),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container.read(productFilterProvider.notifier).applyAll(initial);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: FilterSheet(categories: categories, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextField field(WidgetTester tester, String label) =>
      tester.widget<TextField>(
        find.ancestor(of: find.text(label), matching: find.byType(TextField)),
      );

  group('FilterSheet (07.1 SCR-CAT-03)', () {
    testWidgets('muestra categoría, precio, disponibilidad y orden', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Tacos'), findsOneWidget);
      expect(find.text('Precio mínimo'), findsOneWidget);
      expect(find.text('Precio máximo'), findsOneWidget);
      expect(find.text('Solo productos disponibles'), findsOneWidget);
      expect(find.text('Ordenar por'), findsOneWidget);
      expect(find.text('Aplicar filtros'), findsOneWidget);
      expect(find.text('Limpiar filtros'), findsOneWidget);
    });

    testWidgets('precarga el filtro activo', (tester) async {
      await pumpSheet(
        tester,
        initial: const ProductFilter(
          categoryId: 'c1',
          precioMin: 40,
          precioMax: 200,
          disponible: false,
          sort: ProductSort.precioDesc,
        ),
      );

      expect(field(tester, 'Precio mínimo').controller?.text, '40');
      expect(field(tester, 'Precio máximo').controller?.text, '200');
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(
        tester
            .widget<DropdownButton<ProductSort>>(
              find.byType(DropdownButton<ProductSort>),
            )
            .value,
        ProductSort.precioDesc,
      );
    });

    testWidgets('aplicar Propaga categoría, precio, disponibilidad y orden', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Bebidas'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.ancestor(
          of: find.text('Precio mínimo'),
          matching: find.byType(TextField),
        ),
        '30',
      );
      await tester.enterText(
        find.ancestor(
          of: find.text('Precio máximo'),
          matching: find.byType(TextField),
        ),
        '150',
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<ProductSort>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Precio descendente').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      final applied = container.read(productFilterProvider);
      expect(applied.categoryId, 'c2');
      expect(applied.precioMin, 30);
      expect(applied.precioMax, 150);
      expect(applied.disponible, isFalse);
      expect(applied.sort, ProductSort.precioDesc);
      expect(applied.page, 1, reason: 'un filtro nuevo reinicia la paginación');
    });

    testWidgets('rechaza un rango invertido sin aplicar', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(
        find.ancestor(
          of: find.text('Precio mínimo'),
          matching: find.byType(TextField),
        ),
        '500',
      );
      await tester.enterText(
        find.ancestor(
          of: find.text('Precio máximo'),
          matching: find.byType(TextField),
        ),
        '100',
      );
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Aplicar filtros'), findsOneWidget);
      expect(
        find.text('El mínimo no puede ser mayor que el máximo'),
        findsOneWidget,
      );
      expect(container.read(productFilterProvider).precioMin, isNull);
    });

    testWidgets('ignora un precio no numérico', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(
        find.ancestor(
          of: find.text('Precio mínimo'),
          matching: find.byType(TextField),
        ),
        'gratis',
      );
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      expect(container.read(productFilterProvider).precioMin, isNull);
    });

    testWidgets('"Limpiar filtros" vuelve al valor por defecto', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        initial: const ProductFilter(
          categoryId: 'c1',
          precioMin: 40,
          precioMax: 200,
          disponible: false,
          sort: ProductSort.nombreAsc,
        ),
      );

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();

      expect(field(tester, 'Precio mínimo').controller?.text, isEmpty);
      expect(field(tester, 'Precio máximo').controller?.text, isEmpty);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );

      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      final applied = container.read(productFilterProvider);
      expect(applied.categoryId, isNull);
      expect(applied.precioMin, isNull);
      expect(applied.precioMax, isNull);
      expect(applied.disponible, isTrue);
      expect(applied.sort, ProductSort.relevancia);
    });

    testWidgets('la hoja se cierra con el botón de cerrar', (tester) async {
      var closed = false;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: FilterSheet(
                categories: const [quickbiteTacos],
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });
  });
}
