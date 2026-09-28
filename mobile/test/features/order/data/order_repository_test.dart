import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/order/data/order_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/order/data/order_repository_impl.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/fake_http.dart';

const _direccionId = '22222222-2222-2222-2222-222222222222';
const _ordenId = '55555555-5555-5555-5555-555555555555';

void main() {
  late FakeHttpAdapter http;
  late OrderRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = OrderRepositoryImpl(OrderRemoteDataSource(ApiClient(dio: dio)));
  });

  group('createOrder', () {
    test('envía el contrato que espera POST /orders', () async {
      http.on('POST', '/orders', orderJson());

      await repository.createOrder(
        direccionId: _direccionId,
        direccionSnapshot: 'Av. Reforma 222, Centro',
        metodoPago: MetodoPago.tarjeta,
      );

      final body = http.lastRequest().data as Map<String, dynamic>;
      expect(body['direccionId'], _direccionId);
      expect(body['direccionSnapshot'], 'Av. Reforma 222, Centro');
      expect(body['metodoPago'], 'tarjeta');
    });

    test('las notas de entrega viajan en el snapshot (la API no tiene campo)', () async {
      http.on('POST', '/orders', orderJson());

      await repository.createOrder(
        direccionId: _direccionId,
        direccionSnapshot: 'Av. Reforma 222, Centro',
        metodoPago: MetodoPago.efectivo,
        notasEntrega: 'Tocar el timbre',
      );

      final body = http.lastRequest().data as Map<String, dynamic>;
      expect(
        body['direccionSnapshot'],
        contains('Nota: Tocar el timbre'),
      );
    });

    test('sin notas el snapshot queda limpio', () async {
      http.on('POST', '/orders', orderJson());

      await repository.createOrder(
        direccionId: _direccionId,
        direccionSnapshot: 'Av. Reforma 222, Centro',
        metodoPago: MetodoPago.efectivo,
        notasEntrega: '   ',
      );

      final body = http.lastRequest().data as Map<String, dynamic>;
      expect(body['direccionSnapshot'], 'Av. Reforma 222, Centro');
    });

    test('mapea el pedido creado por la API', () async {
      http.on('POST', '/orders', orderJson(total: 171.0));

      final order = await repository.createOrder(
        direccionSnapshot: 'Av. Reforma 222, Centro',
        metodoPago: MetodoPago.efectivo,
      );

      expect(order.id, _ordenId);
      expect(order.numeroPedido, 'QB-20260927-AB12CD');
      expect(order.estado, 'Pendiente');
      expect(order.total, 171.0);
    });

    test('omite la dirección cuando el pedido usa un snapshot suelto', () async {
      http.on('POST', '/orders', orderJson());

      await repository.createOrder(
        direccionSnapshot: 'Snack 3, junto a la gasolinera',
        metodoPago: MetodoPago.efectivo,
      );

      final body = http.lastRequest().data as Map<String, dynamic>;
      expect(body.containsKey('direccionId'), isFalse);
    });

    test('propaga el 400 de carrito vacío como error de validación', () async {
      http.onError(
        'POST',
        '/orders',
        statusCode: 400,
        body: errorBodyJson('Carrito vacio'),
      );

      await expectLater(
        repository.createOrder(
          direccionSnapshot: 'Centro',
          metodoPago: MetodoPago.efectivo,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'mensaje',
            contains('Carrito vacio'),
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> orderJson({double total = 100.0}) => {
  'id': _ordenId,
  'numeroPedido': 'QB-20260927-AB12CD',
  'estado': 'Pendiente',
  'total': total,
  'creadoEn': '2026-09-27T15:04:00Z',
};
