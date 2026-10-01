import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/order/data/order_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/order/data/order_repository_impl.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/fake_http.dart';

const _ordenId = '55555555-5555-5555-5555-555555555555';

void main() {
  late FakeHttpAdapter http;
  late OrderRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = OrderRepositoryImpl(
      OrderRemoteDataSource(ApiClient(dio: dio)),
    );
  });

  group('listOrders', () {
    test('mapea la lista de pedidos del cliente', () async {
      http.on('GET', '/orders', [
        {
          'id': _ordenId,
          'numeroPedido': 'QB-20260927-AB12CD',
          'estado': 'EnCamino',
          'total': 171.0,
          'creadoEn': '2026-09-27T15:04:00Z',
          'latitud': 13.75,
          'longitud': -89.15,
        },
      ]);

      final pedidos = await repository.listOrders();

      expect(pedidos, hasLength(1));
      expect(pedidos.single.id, _ordenId);
      expect(pedidos.single.estado, 'EnCamino');
      expect(pedidos.single.estadoPedido, EstadoPedido.enCamino);
      expect(pedidos.single.total, 171.0);
      expect(pedidos.single.creadoEn, isNotNull);
      expect(pedidos.single.latitud, 13.75);
      expect(pedidos.single.longitud, -89.15);
    });

    test('el filtro de estado se aplica en el cliente', () async {
      http.on('GET', '/orders', [
        _pedidoJson('a1', 'QB-1', 'Entregado'),
        _pedidoJson('a2', 'QB-2', 'Preparando'),
        _pedidoJson('a3', 'QB-3', 'Cancelado'),
      ]);

      final pedidos = await repository.listOrders();

      expect(
        pedidos.where((p) => FiltroPedido.enCurso.incluye(p.estadoPedido)),
        hasLength(1),
      );
      expect(
        pedidos.where((p) => FiltroPedido.cancelados.incluye(p.estadoPedido)),
        hasLength(1),
      );
      expect(
        pedidos.where((p) => FiltroPedido.todos.incluye(p.estadoPedido)),
        hasLength(3),
      );
    });
  });

  group('getStatus', () {
    test('mapea el estado consultado para el polling', () async {
      http.on('GET', '/orders/$_ordenId/status', {
        'id': _ordenId,
        'estado': 'Preparando',
        'actualizadoEn': '2026-09-27T15:10:00Z',
      });

      final estado = await repository.getStatus(_ordenId);

      expect(estado.estado, EstadoPedido.preparando);
      expect(estado.actualizadoEn, isNotNull);
      expect(estado.actualizadoEn.isUtc, isTrue);
    });

    test('propaga un 404 como pedido inexistente', () async {
      http.onError(
        'GET',
        '/orders/$_ordenId/status',
        statusCode: 404,
        body: errorBodyJson('No encontrado', status: 404, error: 'NotFound'),
      );

      await expectLater(
        repository.getStatus(_ordenId),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('getOrder', () {
    test('expone las coordenadas de destino del pedido', () async {
      http.on('GET', '/orders/$_ordenId', {
        'id': _ordenId,
        'numeroPedido': 'QB-20260927-AB12CD',
        'estado': 'EnCamino',
        'subtotal': 150.0,
        'costoEnvio': 21.0,
        'total': 171.0,
        'items': ['Tacos al pastor'],
        'latitud': 13.75,
        'longitud': -89.15,
      });

      final pedido = await repository.getOrder(_ordenId);

      expect(pedido.latitud, 13.75);
      expect(pedido.longitud, -89.15);
    });

    test('sin coordenadas en la respuesta quedan null', () async {
      http.on('GET', '/orders/$_ordenId', {
        'id': _ordenId,
        'numeroPedido': 'QB-20260927-AB12CD',
        'estado': 'Preparando',
        'subtotal': 150.0,
        'costoEnvio': 21.0,
        'total': 171.0,
        'items': const <String>[],
      });

      final pedido = await repository.getOrder(_ordenId);

      expect(pedido.latitud, isNull);
      expect(pedido.longitud, isNull);
    });
  });

  group('cancelOrder', () {
    test('envía el motivo y no espera cuerpo', () async {
      http.on('PATCH', '/orders/$_ordenId/cancel', '', statusCode: 204);

      await repository.cancelOrder(
        _ordenId,
        motivo: 'Me equivoqué de dirección',
      );

      final body = http.lastRequest().data as Map<String, dynamic>;
      expect(body['motivo'], 'Me equivoqué de dirección');
    });

    test('sin motivo envía la cadena vacía', () async {
      http.on('PATCH', '/orders/$_ordenId/cancel', '', statusCode: 204);

      await repository.cancelOrder(_ordenId);

      final body = http.lastRequest().data as Map<String, dynamic>;
      expect(body['motivo'], '');
    });

    test('propaga un 409 si el pedido ya no se puede cancelar', () async {
      http.onError(
        'PATCH',
        '/orders/$_ordenId/cancel',
        statusCode: 409,
        body: errorBodyJson('El pedido ya no se puede cancelar', status: 409),
      );

      await expectLater(
        repository.cancelOrder(_ordenId),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}

Map<String, dynamic> _pedidoJson(String id, String numero, String estado) => {
  'id': id,
  'numeroPedido': numero,
  'estado': estado,
  'total': 100.0,
  'creadoEn': '2026-09-27T15:04:00Z',
};
