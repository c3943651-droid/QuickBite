import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/cart/data/cart_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/cart/data/cart_repository_impl.dart';

import '../../../support/fake_http.dart';

const _productoId = '11111111-1111-1111-1111-111111111111';
const _itemId = '44444444-4444-4444-4444-444444444444';
const _opcionExtra = '99999999-9999-9999-9999-999999999999';

void main() {
  late FakeHttpAdapter http;
  late CartRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = CartRepositoryImpl(CartRemoteDataSource(ApiClient(dio: dio)));
  });

  group('getCart', () {
    test('mapea el carrito que devuelve la API', () async {
      http.on('GET', '/cart', cartJson());

      final cart = await repository.getCart();

      expect(cart.items, hasLength(1));
      final item = cart.items.single;
      expect(item.id, _itemId);
      expect(item.productoId, _productoId);
      expect(item.nombre, 'Tacos al pastor');
      expect(item.precio, 85.50);
      expect(item.cantidad, 2);
      expect(item.opciones, ['Extra queso']);
      expect(item.subtotal, 171.00);
      expect(cart.subtotal, 171.00);
      expect(cart.costoEnvio, 0);
      expect(cart.total, 171.00);
    });

    test('un carrito vacío no inventa items', () async {
      http.on('GET', '/cart', {
        'id': '00000000-0000-0000-0000-000000000000',
        'items': <Map<String, dynamic>>[],
        'total': 0,
      });

      final cart = await repository.getCart();

      expect(cart.items, isEmpty);
      expect(cart.isEmpty, isTrue);
      expect(cart.total, 0);
    });

    test('deriva el envío cuando la API ya lo incluye en el total', () async {
      http.on('GET', '/cart', {
        ...cartJson(),
        'subtotal': 171.00,
        'costoEnvio': 45.00,
        'total': 216.00,
      });

      final cart = await repository.getCart();

      expect(cart.subtotal, 171.00);
      expect(cart.costoEnvio, 45.00);
      expect(cart.total, 216.00);
    });

    test(
      'un item sin subtotal explícito se calcula por precio x cantidad',
      () async {
        http.on('GET', '/cart', {
          'id': 'cart-1',
          'items': [
            {
              'id': _itemId,
              'productoId': _productoId,
              'nombre': 'Tacos al pastor',
              'precio': 85.50,
              'cantidad': 2,
              'opciones': <String>[],
            },
          ],
          'total': 0,
        });

        final cart = await repository.getCart();

        expect(cart.items.single.subtotal, 171.00);
        expect(cart.subtotal, 171.00);
      },
    );
  });

  group('addItem', () {
    test('envía producto, cantidad, observaciones y opciones', () async {
      http.on('POST', '/cart/items', cartJson(), statusCode: 201);

      await repository.addItem(
        productoId: _productoId,
        cantidad: 2,
        observaciones: 'Sin cebolla',
        opcionIds: const [_opcionExtra],
      );

      final request = http.lastRequest();
      expect(request.method, 'POST');
      expect(request.data, {
        'productoId': _productoId,
        'cantidad': 2,
        'observaciones': 'Sin cebolla',
        'opcionesIds': [_opcionExtra],
      });
    });

    test('omite observaciones y opciones vacías', () async {
      http.on('POST', '/cart/items', cartJson(), statusCode: 201);

      await repository.addItem(productoId: _productoId, cantidad: 1);

      final data = http.lastRequest().data as Map<String, dynamic>;
      expect(data.containsKey('observaciones'), isFalse);
      expect(data.containsKey('opcionesIds'), isFalse);
    });

    test('devuelve el carrito actualizado', () async {
      http.on('POST', '/cart/items', cartJson(), statusCode: 201);

      final cart = await repository.addItem(
        productoId: _productoId,
        cantidad: 2,
      );

      expect(cart.items, hasLength(1));
    });
  });

  group('updateItem', () {
    test('envía cantidad y observaciones', () async {
      http.on('PUT', '/cart/items/$_itemId', cartJson());

      await repository.updateItem(
        itemId: _itemId,
        cantidad: 3,
        observaciones: 'Muy picoso',
      );

      final request = http.lastRequest();
      expect(request.method, 'PUT');
      expect(request.data, {'cantidad': 3, 'observaciones': 'Muy picoso'});
    });

    test('omite observaciones vacías', () async {
      http.on('PUT', '/cart/items/$_itemId', cartJson());

      await repository.updateItem(itemId: _itemId, cantidad: 3);

      final data = http.lastRequest().data as Map<String, dynamic>;
      expect(data['cantidad'], 3);
      expect(data.containsKey('observaciones'), isFalse);
    });
  });

  group('removeItem', () {
    test('borra el item por id', () async {
      http.on('DELETE', '/cart/items/$_itemId', '', statusCode: 204);

      await repository.removeItem(_itemId);

      expect(http.lastRequest().method, 'DELETE');
      expect(http.callsTo('DELETE', '/cart/items/$_itemId'), 1);
    });
  });

  group('clear', () {
    test('vacía el carrito completo', () async {
      http.on('DELETE', '/cart', '', statusCode: 204);

      await repository.clear();

      expect(http.lastRequest().method, 'DELETE');
      expect(http.callsTo('DELETE', '/cart'), 1);
    });
  });

  group('errores', () {
    test('propaga un 400 de stock insuficiente con su mensaje', () async {
      http.onError(
        'POST',
        '/cart/items',
        statusCode: 400,
        body: errorBodyJson('Stock insuficiente'),
      );

      await expectLater(
        repository.addItem(productoId: _productoId, cantidad: 9),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('Stock insuficiente'),
          ),
        ),
      );
    });
  });
}
