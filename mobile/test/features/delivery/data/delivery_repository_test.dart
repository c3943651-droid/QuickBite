import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/delivery/data/delivery_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/delivery/data/delivery_repository_impl.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import '../../../support/fake_http.dart';

/// `OrderResponse` del backend, en camelCase: es el mismo DTO que consume la
/// parte de cliente, así que el repartidor ve exactamente los mismos campos.
Map<String, dynamic> pedidoJson({
  String id = 'o1',
  String numeroPedido = 'QB-001',
  String estado = 'listo',
  double total = 250.5,
  String? creadoEn = '2026-09-28T18:00:00Z',
}) {
  return {
    'id': id,
    'numeroPedido': numeroPedido,
    'estado': estado,
    'total': total,
    'creadoEn': ?creadoEn,
  };
}

Map<String, dynamic> statsJson({
  int entregasTotales = 12,
  int entregasDelMes = 3,
  double tiempoPromedio = 27.5,
  int pedidosAsignados = 15,
  int cancelaciones = 1,
}) {
  return {
    'deliveryPersonId': 'd1',
    'entregasTotales': entregasTotales,
    'entregasDelMes': entregasDelMes,
    'tiempoPromedioEntregaMinutos': tiempoPromedio,
    'pedidosAsignadosActivos': pedidosAsignados,
    'cancelaciones': cancelaciones,
  };
}

void main() {
  late FakeHttpAdapter http;
  late DeliveryRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = DeliveryRepositoryImpl(
      DeliveryRemoteDataSource(ApiClient(dio: dio)),
    );
  });

  group('pedidos disponibles (SCR-DEL-01)', () {
    test('lee GET /delivery/available como lista de pedidos', () async {
      http.on('GET', '/delivery/available', [
        pedidoJson(),
        pedidoJson(id: 'o2', numeroPedido: 'QB-002'),
      ]);

      final pedidos = await repository.pedidosDisponibles();

      expect(pedidos, hasLength(2));
      expect(pedidos.first.id, 'o1');
      expect(pedidos.first.numeroPedido, 'QB-001');
      expect(pedidos.first.estadoPedido, EstadoPedido.listo);
      expect(pedidos.last.numeroPedido, 'QB-002');
    });

    test('una lista vacía se devuelve como lista vacía', () async {
      http.on('GET', '/delivery/available', const []);

      expect(await repository.pedidosDisponibles(), isEmpty);
    });

    test(
      'un campo que la API no manda deja el total en cero, sin romper',
      () async {
        http.on('GET', '/delivery/available', [pedidoJson(total: 0)]);

        final pedidos = await repository.pedidosDisponibles();
        expect(pedidos.single.total, 0);
      },
    );
  });

  group('aceptar entrega (SCR-DEL-02)', () {
    test('el id va antes de accept, como en el backend', () async {
      http.on('POST', '/delivery/o1/accept', '', statusCode: 204);

      await repository.aceptar('o1');

      expect(http.lastRequest().path, '/delivery/o1/accept');
      expect(http.lastRequest().method, 'POST');
    });

    test('la API responde 204 sin cuerpo y eso no es un error', () async {
      http.on('POST', '/delivery/o1/accept', '', statusCode: 204);

      await expectLater(repository.aceptar('o1'), completes);
    });

    test('un 400 porque el pedido ya no está disponible se propaga', () async {
      http.onError(
        'POST',
        '/delivery/o1/accept',
        statusCode: 400,
        body: {'message': 'El pedido ya no está disponible.'},
      );

      expect(() => repository.aceptar('o1'), throwsA(isA<AppException>()));
    });
  });

  group('entrega activa (SCR-DEL-03)', () {
    test('lee GET /delivery/active', () async {
      http.on('GET', '/delivery/active', [pedidoJson(estado: 'EnCamino')]);

      final activa = await repository.entregaActiva();

      expect(activa, isNotNull);
      expect(activa!.id, 'o1');
      expect(activa.estadoPedido, EstadoPedido.enCamino);
    });

    test('sin pedidos en camino la entrega activa es null', () async {
      http.on('GET', '/delivery/active', const []);

      expect(await repository.entregaActiva(), isNull);
    });

    test('con varios pedidos devuelve el más reciente', () async {
      http.on('GET', '/delivery/active', [
        pedidoJson(id: 'viejo', creadoEn: '2026-09-27T10:00:00Z'),
        pedidoJson(id: 'nuevo', creadoEn: '2026-09-28T18:00:00Z'),
      ]);

      expect((await repository.entregaActiva())?.id, 'nuevo');
    });
  });

  group('completar entrega (SCR-DEL-04)', () {
    test('el id va antes de complete, como en el backend', () async {
      http.on('POST', '/delivery/o1/complete', '', statusCode: 204);

      await repository.completar('o1');

      expect(http.lastRequest().path, '/delivery/o1/complete');
    });
  });

  group('historial de entregas (SCR-DEL-05)', () {
    test(
      'lee GET /delivery/history como lista, sin envoltorio de paginación',
      () async {
        http.on('GET', '/delivery/history', [
          pedidoJson(estado: 'entregado'),
          pedidoJson(id: 'o2', numeroPedido: 'QB-002', estado: 'entregado'),
        ]);

        final historial = await repository.historialEntregas();

        expect(historial, hasLength(2));
        expect(historial.first.estadoPedido, EstadoPedido.entregado);
      },
    );

    test('un historial vacío se devuelve como lista vacía', () async {
      http.on('GET', '/delivery/history', const []);

      expect(await repository.historialEntregas(), isEmpty);
    });
  });

  group('estadísticas (SCR-DEL-06)', () {
    test('mapea las métricas que devuelve el backend', () async {
      http.on('GET', '/delivery/stats', statsJson());

      final stats = await repository.estadisticas();

      expect(stats.entregasTotales, 12);
      expect(stats.entregasDelMes, 3);
      expect(stats.tiempoPromedioEntregaMinutos, 27.5);
      expect(stats.pedidosAsignados, 15);
      expect(stats.cancelaciones, 1);
    });

    test('un repartidor sin entregas recibe ceros', () async {
      http.on(
        'GET',
        '/delivery/stats',
        statsJson(
          entregasTotales: 0,
          entregasDelMes: 0,
          tiempoPromedio: 0,
          pedidosAsignados: 0,
          cancelaciones: 0,
        ),
      );

      expect((await repository.estadisticas()).estaVacia, isTrue);
    });
  });
}
