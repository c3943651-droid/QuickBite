import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/catalog/data/catalog_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/catalog/data/catalog_repository_impl.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';

import '../../../support/fake_http.dart';

void main() {
  late FakeHttpAdapter http;
  late CatalogRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = CatalogRepositoryImpl(
      CatalogRemoteDataSource(ApiClient(dio: dio)),
    );
  });

  group('getCategories', () {
    test('mapea la lista de categorías', () async {
      http.on('GET', '/categories', [
        categoryJson(nombre: 'Tacos', orden: 1),
        categoryJson(
          id: '44444444-4444-4444-4444-444444444444',
          nombre: 'Bebidas',
          orden: 2,
          icon: 'local_cafe',
        ),
      ]);

      final categories = await repository.getCategories();

      expect(categories, hasLength(2));
      expect(categories.first.nombre, 'Tacos');
      expect(categories.first.activo, isTrue);
      expect(categories.last.icon, 'local_cafe');
    });
  });

  group('getProducts', () {
    test('mapea el envelope paginado', () async {
      http.on(
        'GET',
        '/products',
        pagedResponseJson(data: [productJson()], total: 1, limit: 12),
      );

      final page = await repository.getProducts(const ProductFilter());

      expect(page.items, hasLength(1));
      expect(page.total, 1);
      expect(page.page, 1);
      expect(page.limit, 12);
      expect(page.hasMore, isFalse);
      expect(page.items.first.precio, 85.50);
      expect(page.items.first.categoria?.nombre, 'Tacos');
      expect(page.items.first.stockMinimo, 5);
    });

    test('envía los query params que espera el backend', () async {
      http.on('GET', '/products', pagedResponseJson(data: []));

      await repository.getProducts(
        const ProductFilter(
          categoryId: '22222222-2222-2222-2222-222222222222',
          search: 'pastor',
          sort: ProductSort.precioAsc,
          page: 3,
          limit: 12,
        ),
      );

      final query = http.lastRequest().queryParameters;
      expect(query['categoriaId'], '22222222-2222-2222-2222-222222222222');
      expect(query['search'], 'pastor');
      expect(query['orden'], 'precio_asc');
      expect(query['page'], 3);
      expect(query['limit'], 12);
      expect(query['disponible'], true);
    });

    test('omite la búsqueda vacía', () async {
      http.on('GET', '/products', pagedResponseJson(data: []));

      await repository.getProducts(const ProductFilter(search: ''));

      expect(http.lastRequest().queryParameters.containsKey('search'), isFalse);
    });

    test('traduce cada opción de orden a su valor de API', () async {
      http.on('GET', '/products', pagedResponseJson(data: []));

      for (final entry in {
        ProductSort.relevancia: 'relevancia',
        ProductSort.precioAsc: 'precio_asc',
        ProductSort.precioDesc: 'precio_desc',
        ProductSort.nombreAsc: 'nombre_asc',
        ProductSort.nombreDesc: 'nombre_desc',
      }.entries) {
        await repository.getProducts(ProductFilter(sort: entry.key));
        expect(http.lastRequest().queryParameters['orden'], entry.value);
      }
    });
  });

  group('getProduct', () {
    test('mapea el detalle con opciones y stock', () async {
      http.on('GET', '/products/11111111-1111-1111-1111-111111111111', {
        ...productJson(stock: 8),
        'opciones': [
          {
            'id': 'a',
            'nombre': 'Extra queso',
            'precioAdicional': 12.0,
            'activo': true,
          },
          {
            'id': 'b',
            'nombre': 'Sin cebolla',
            'precioAdicional': 0.0,
            'activo': false,
          },
        ],
      });

      final product = await repository.getProduct(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(product.nombre, 'Tacos al pastor');
      expect(product.stock, 8);
      expect(product.categoria?.nombre, 'Tacos');
    });

    test('tolera productos sin categoría', () async {
      final json = productJson()..remove('categoria');
      http.on('GET', '/products/11111111-1111-1111-1111-111111111111', json);

      final product = await repository.getProduct(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(product.categoria, isNull);
    });
  });

  group('getProductOptions', () {
    test('mapea las opciones con precio adicional', () async {
      http.on('GET', '/products/11111111-1111-1111-1111-111111111111/options', [
        {
          'id': 'a',
          'nombre': 'Extra queso',
          'precioAdicional': 12.0,
          'activo': true,
        },
        {
          'id': 'b',
          'nombre': 'Sin cebolla',
          'precioAdicional': 0.0,
          'activo': false,
        },
      ]);

      final options = await repository.getProductOptions(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(options, hasLength(2));
      expect(options.first.nombre, 'Extra queso');
      expect(options.first.precioAdicional, 12.0);
      expect(options.last.activo, isFalse);
    });
  });

  group('ProductPage', () {
    const page1 = ProductPage(
      items: [Product(id: '1', nombre: 'A', precio: 10, disponible: true)],
      page: 1,
      limit: 1,
      total: 2,
      totalPages: 2,
    );
    const page2 = ProductPage(
      items: [Product(id: '2', nombre: 'B', precio: 20, disponible: true)],
      page: 2,
      limit: 1,
      total: 2,
      totalPages: 2,
    );

    test('hasMore refleja page < totalPages', () {
      expect(page1.hasMore, isTrue);
      expect(page2.hasMore, isFalse);
      expect(const ProductPage.empty().hasMore, isFalse);
    });

    test('merge concatena los items y conserva la última página', () {
      final merged = page1.merge(page2);
      expect(merged.items.map((p) => p.id), ['1', '2']);
      expect(merged.page, 2);
      expect(merged.total, 2);
    });
  });
}
