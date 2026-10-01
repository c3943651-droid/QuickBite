import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_repository.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/product_detail_screen.dart';

import '../../../support/cart_fakes.dart';
import '../../../support/contrast.dart';

class _DetalleRepository implements CatalogRepository {
  Product? product;
  List<ProductOption> options = const [];
  Object? error;
  int productCalls = 0;
  int optionCalls = 0;

  @override
  Future<List<PromotionBanner>> getPromotions() async => const [];

  @override
  Future<Product> getProduct(String id) async {
    productCalls++;
    if (error != null) {
      throw error!;
    }
    if (product == null) {
      throw const NotFoundException('Producto no encontrado');
    }
    return product!;
  }

  @override
  Future<List<ProductOption>> getProductOptions(String id) async {
    optionCalls++;
    return options;
  }

  @override
  Future<List<Category>> getCategories() => throw UnimplementedError();

  @override
  Future<ProductPage> getProducts(ProductFilter filter) =>
      throw UnimplementedError();
}

const _tacos = Product(
  id: 'p1',
  nombre: 'Tacos al pastor',
  precio: 85.50,
  descripcion: 'Carne marinada con piña y cilantro.',
  disponible: true,
  imagenUrl: 'https://cdn.test/pastor.jpg',
  categoria: Category(id: 'c1', nombre: 'Tacos', orden: 1, activo: true),
);

const _opciones = [
  ProductOption(
    id: 'o1',
    nombre: 'Extra queso',
    precioAdicional: 12,
    activo: true,
  ),
  ProductOption(
    id: 'o2',
    nombre: 'Sin cebolla',
    precioAdicional: 0,
    activo: true,
  ),
];

void main() {
  late _DetalleRepository catalog;
  late FakeCartRepository cart;
  late ProviderContainer container;

  setUp(() {
    catalog = _DetalleRepository()
      ..product = _tacos
      ..options = _opciones;
    cart = FakeCartRepository();
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        cartRepositoryProvider.overrideWithValue(cart),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpDetalle(
    WidgetTester tester, {
    String id = 'p1',
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/product/$id',
      routes: [
        GoRoute(
          path: '/product/:id',
          builder: (_, state) =>
              ProductDetailScreen(productoId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, _) => const Scaffold(body: Text('Carrito real')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Catálogo real')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router, theme: theme),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ProductDetailScreen (07.1 SCR-CAT-04)', () {
    testWidgets('muestra nombre, precio, descripción y disponibilidad', (
      tester,
    ) async {
      await pumpDetalle(tester);

      expect(find.text('Tacos al pastor'), findsOneWidget);
      expect(find.text(r'$85.50'), findsWidgets);
      expect(find.text('Carne marinada con piña y cilantro.'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('muestra la imagen del producto', (tester) async {
      await pumpDetalle(tester);

      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
        findsOneWidget,
      );
    });

    testWidgets('sin imagen muestra el placeholder', (tester) async {
      catalog.product = const Product(
        id: 'p1',
        nombre: 'Tacos al pastor',
        precio: 85.50,
        disponible: true,
      );
      await pumpDetalle(tester);

      expect(find.byIcon(Icons.fastfood_outlined), findsWidgets);
    });

    testWidgets('lista las opciones con su precio adicional', (tester) async {
      await pumpDetalle(tester);

      expect(find.text('Extra queso'), findsOneWidget);
      expect(find.text('Sin cebolla'), findsOneWidget);
      expect(find.text(r'+$12.00'), findsOneWidget);
    });

    testWidgets('cantidad inicial 1 y total igual al precio base', (
      tester,
    ) async {
      await pumpDetalle(tester);

      expect(find.text(r'Agregar al carrito - $85.50'), findsOneWidget);
    });

    testWidgets('seleccionar una opción suma su precio al total', (
      tester,
    ) async {
      await pumpDetalle(tester);

      await tester.tap(find.text('Extra queso'));
      await tester.pumpAndSettle();

      expect(find.text(r'Agregar al carrito - $97.50'), findsOneWidget);
    });

    testWidgets('subir la cantidad multiplica precio y opciones', (
      tester,
    ) async {
      await pumpDetalle(tester);

      await tester.tap(find.text('Extra queso'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text(r'Agregar al carrito - $195.00'), findsOneWidget);
    });

    testWidgets('bajar la cantidad no baja de 1', (tester) async {
      await pumpDetalle(tester);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(find.text(r'Agregar al carrito - $85.50'), findsOneWidget);
    });

    testWidgets('el resumen desglosa unitario, opciones y total', (
      tester,
    ) async {
      await pumpDetalle(tester);
      await tester.tap(find.text('Extra queso'));
      await tester.pumpAndSettle();

      expect(find.text('Precio unitario'), findsOneWidget);
      expect(find.text('Opciones'), findsOneWidget);
      expect(find.text('Cantidad'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(r'$12.00'), findsWidgets);
      expect(find.text(r'$97.50'), findsWidgets);
    });

    testWidgets('agrega al carrito con opciones, notas y cantidad', (
      tester,
    ) async {
      await pumpDetalle(tester);

      await tester.tap(find.text('Extra queso'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Sin cilantro');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Agregar al carrito'));
      await tester.pumpAndSettle();

      expect(cart.adds, hasLength(1));
      expect(cart.adds.single.productoId, 'p1');
      expect(cart.adds.single.ids, ['o1']);
      expect(cart.adds.single.observaciones, 'Sin cilantro');
      expect(cart.adds.single.cantidad, 2);
      expect(find.textContaining('Agregado al carrito'), findsOneWidget);
    });

    testWidgets('un producto agotado deshabilita opciones y botón', (
      tester,
    ) async {
      catalog.product = const Product(
        id: 'p1',
        nombre: 'Tacos al pastor',
        precio: 85.50,
        disponible: false,
      );
      await pumpDetalle(tester);

      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('No disponible'), findsOneWidget);

      final boton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('No disponible'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('un producto agotado no se puede agregar', (tester) async {
      catalog.product = const Product(
        id: 'p1',
        nombre: 'Tacos al pastor',
        precio: 85.50,
        disponible: false,
      );
      await pumpDetalle(tester);

      await tester.tap(find.text('No disponible'));
      await tester.pumpAndSettle();

      expect(cart.adds, isEmpty);
    });

    testWidgets('el error de red ofrece reintentar', (tester) async {
      catalog.error = const NetworkException();
      await pumpDetalle(tester);

      expect(find.text('Reintentar'), findsOneWidget);
      final llamadasAntes = catalog.productCalls;

      catalog.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(catalog.productCalls, greaterThan(llamadasAntes));
      expect(find.text('Tacos al pastor'), findsOneWidget);
    });

    testWidgets('un producto inexistente avisa y ofrece volver al catálogo', (
      tester,
    ) async {
      catalog.product = null;
      await pumpDetalle(tester, id: 'p99');

      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Ir al catálogo'));
      await tester.pumpAndSettle();

      expect(find.text('Catálogo real'), findsOneWidget);
    });

    testWidgets('muestra el estado de carga', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProductDetailScreen(productoId: 'p1')),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('la flecha de volver no invade la barra de estado', (
      tester,
    ) async {
      // Con la barra de sistema presente (m notch o barra de estado de Android).
      tester.view.padding = const FakeViewPadding(top: 96);
      addTearDown(tester.view.resetPadding);

      await pumpDetalle(tester, theme: AppTheme.light);

      final boton = tester.getRect(find.byTooltip('Volver'));
      expect(
        boton.top,
        greaterThanOrEqualTo(96),
        reason: 'la flecha debe quedar por debajo de la barra de estado',
      );
    });

    testWidgets(
      'el número de unidades y los textos secundarios tienen contraste',
      (tester) async {
        await pumpDetalle(tester, theme: AppTheme.light);

        // Con color explícito: sin él el texto cae en el estilo heredado y deja
        // de respetar el modo oscuro y el alto contraste.
        final cantidad = tester.widget<Text>(find.text('1'));
        expect(cantidad.style?.color, isNotNull);
        expect(
          contraste(colorDe(cantidad.style), AppColors.surface),
          greaterThan(4.5),
        );

        for (final etiqueta in ['Personaliza tu pedido', 'Ajustar cantidad']) {
          final texto = tester.widget<Text>(find.text(etiqueta));
          expect(
            texto.style?.color,
            isNotNull,
            reason: '$etiqueta necesita color explícito',
          );
          expect(
            contraste(colorDe(texto.style), AppColors.surface),
            greaterThan(4.5),
            reason: '$etiqueta no se lee sobre fondo claro',
          );
        }
      },
    );
  });
}
