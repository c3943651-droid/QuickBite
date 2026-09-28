import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/notification/data/notification_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/notification/data/notification_repository_impl.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';

import '../../../support/fake_http.dart';

const _notificacionId = '77777777-7777-7777-7777-777777777777';
const _pedidoId = '55555555-5555-5555-5555-555555555555';

Map<String, dynamic> _json({
  String id = _notificacionId,
  int tipo = 2,
  String titulo = 'Tu pedido va en camino',
  String? pedidoId,
  bool leido = false,
}) => {
  'id': id,
  'usuarioId': '33333333-3333-3333-3333-333333333333',
  'tipo': tipo,
  'titulo': titulo,
  'mensaje': 'El repartidor ya salió del restaurante.',
  'pedidoId': pedidoId,
  'leido': leido,
  'leidoEn': null,
  'creadoEn': '2026-09-27T15:04:00Z',
};

void main() {
  late FakeHttpAdapter http;
  late NotificationRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = NotificationRepositoryImpl(
      NotificationRemoteDataSource(ApiClient(dio: dio)),
    );
  });

  group('listNotifications', () {
    test('mapea la lista que devuelve la API', () async {
      http.on('GET', '/notifications', [
        _json(pedidoId: _pedidoId),
        _json(id: 'n2', tipo: 4, titulo: 'Mantenimiento'),
      ]);

      final notificaciones = await repository.listNotifications();

      expect(notificaciones, hasLength(2));
      expect(notificaciones.first.id, _notificacionId);
      expect(notificaciones.first.tipo, TipoNotificacion.cambioEstado);
      expect(notificaciones.first.titulo, 'Tu pedido va en camino');
      expect(notificaciones.first.pedidoId, _pedidoId);
      expect(notificaciones.first.leido, isFalse);
      expect(notificaciones.first.creadoEn, isNotNull);
      expect(notificaciones.last.tipo, TipoNotificacion.sistema);
    });

    test('envía unreadOnly para pedir solo las no leídas', () async {
      http.on('GET', '/notifications', [_json()]);

      await repository.listNotifications(soloNoLeidas: true);

      final peticion = http.lastRequest();
      expect(peticion.queryParameters['unreadOnly'], isTrue);
    });

    test('sin filtro no manda unreadOnly', () async {
      http.on('GET', '/notifications', [_json()]);

      await repository.listNotifications();

      expect(
        http.lastRequest().queryParameters.containsKey('unreadOnly'),
        isFalse,
      );
    });

    test(
      'un error del servidor se traduce a una excepción de la app',
      () async {
        http.onError(
          'GET',
          '/notifications',
          statusCode: 500,
          body: errorBodyJson(
            'Error interno',
            status: 500,
            error: 'ServerError',
          ),
        );

        await expectLater(
          repository.listNotifications(),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('marcarLeida', () {
    test('marca una notificación como leída', () async {
      http.on(
        'PATCH',
        '/notifications/$_notificacionId/read',
        '',
        statusCode: 204,
      );

      await repository.marcarLeida(_notificacionId);

      expect(http.lastRequest().method, 'PATCH');
    });

    test('un id inexistente propaga el 404', () async {
      http.onError(
        'PATCH',
        '/notifications/$_notificacionId/read',
        statusCode: 404,
        body: errorBodyJson('No encontrado', status: 404, error: 'NotFound'),
      );

      await expectLater(
        repository.marcarLeida(_notificacionId),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('marcarTodasLeidas', () {
    test('marca todas con un solo PATCH', () async {
      http.on('PATCH', '/notifications/read-all', '', statusCode: 204);

      await repository.marcarTodasLeidas();

      expect(http.lastRequest().method, 'PATCH');
      expect(http.lastRequest().path, '/notifications/read-all');
    });
  });
}
