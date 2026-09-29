import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/profile/data/seguridad_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/profile/data/seguridad_repository_impl.dart';

import '../../../support/fake_http.dart';
import '../../../support/fake_token_storage.dart';

const sesionId = '99999999-9999-9999-9999-999999999999';

Map<String, dynamic> sesionJson({
  String id = sesionId,
  String? ipOrigen = '203.0.113.7',
  String? userAgent = 'Chrome 141 / Android',
  String creadoEn = '2026-09-20T10:00:00Z',
  String expiraEn = '2026-10-20T10:00:00Z',
  bool esActual = false,
}) {
  return {
    'id': id,
    'ip_origen': ipOrigen,
    'user_agent': userAgent,
    'creado_en': creadoEn,
    'expira_en': expiraEn,
    'es_actual': esActual,
  };
}

void main() {
  late FakeHttpAdapter http;
  late InMemoryTokenStorage tokens;
  late SeguridadRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    tokens = InMemoryTokenStorage(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = SeguridadRepositoryImpl(
      SeguridadRemoteDataSource(ApiClient(dio: dio)),
      tokens,
    );
  });

  group('mapeo tolerante de sesiones', () {
    test('una fecha mal formada no tira la lista entera', () async {
      http.on('GET', '/users/sessions', [
        sesionJson(id: 's1'),
        sesionJson(id: 's2', creadoEn: 'no-es-una-fecha'),
      ]);

      final sesiones = await repository.fetchSessions();

      // La fila sobrevive: solo se pierde la fecha, que es un dato informativo.
      expect(sesiones, hasLength(2));
      expect(sesiones.first.creadoEn, isNotNull);
      expect(sesiones.last.creadoEn, isNull);
    });

    test('sin `es_actual` la sesión no se marca como actual', () async {
      final body = sesionJson()..remove('es_actual');
      http.on('GET', '/users/sessions', [body]);

      final sesiones = await repository.fetchSessions();

      expect(sesiones.single.esActual, isFalse);
    });

    test('sin `id` la sesión no rompe la lista', () async {
      final body = sesionJson()..remove('id');
      http.on('GET', '/users/sessions', [body]);

      final sesiones = await repository.fetchSessions();

      expect(sesiones, hasLength(1));
      expect(sesiones.single.id, '');
    });
  });

  group('listar sesiones (04 §4.9)', () {
    test('mapea la respuesta con los campos en snake_case', () async {
      http.on('GET', '/users/sessions', [sesionJson()]);

      final sesiones = await repository.fetchSessions();

      expect(http.lastRequest().path, '/users/sessions');
      expect(sesiones, hasLength(1));
      expect(sesiones.single.id, sesionId);
      expect(sesiones.single.ipOrigen, '203.0.113.7');
      expect(sesiones.single.userAgent, 'Chrome 141 / Android');
      expect(sesiones.single.creadoEn, DateTime.utc(2026, 9, 20, 10));
      expect(sesiones.single.expiraEn, DateTime.utc(2026, 10, 20, 10));
      expect(sesiones.single.esActual, isFalse);
    });

    test(
      'envía el refresh token para que la API marque la sesión actual',
      () async {
        http.on('GET', '/users/sessions', <Map<String, dynamic>>[]);

        await repository.fetchSessions();

        expect(
          http.lastRequest().headers['X-Refresh-Token'],
          'refresh-1',
          reason: 'sin el token la API no puede resolver es_actual (04 §4.9)',
        );
      },
    );

    test('sin sesión guardada no envía la cabecera de sesión actual', () async {
      http.on('GET', '/users/sessions', <Map<String, dynamic>>[]);
      final vacio = SeguridadRepositoryImpl(
        SeguridadRemoteDataSource(
          ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
              ..httpClientAdapter = http,
          ),
        ),
        InMemoryTokenStorage(),
      );

      await vacio.fetchSessions();

      expect(http.lastRequest().headers, isNot(contains('X-Refresh-Token')));
    });

    test('ip y agente ausentes no rompen el mapeo', () async {
      http.on('GET', '/users/sessions', [
        sesionJson(ipOrigen: null, userAgent: null),
      ]);

      final sesiones = await repository.fetchSessions();

      expect(sesiones.single.ipOrigen, isNull);
      expect(sesiones.single.userAgent, isNull);
    });

    test('una lista vacía no es un error', () async {
      http.on('GET', '/users/sessions', <Map<String, dynamic>>[]);

      expect(await repository.fetchSessions(), isEmpty);
    });
  });

  group('revocar sesión (04 §4.10)', () {
    test('borra la sesión indicada', () async {
      http.on('DELETE', '/users/sessions/$sesionId', '', statusCode: 204);

      await repository.revokeSession(sesionId);

      expect(http.lastRequest().method, 'DELETE');
      expect(http.lastRequest().path, '/users/sessions/$sesionId');
    });

    test('un 404 se traduce a NotFoundException', () async {
      http.onError(
        'DELETE',
        '/users/sessions/$sesionId',
        statusCode: 404,
        body: errorBodyJson(
          'La sesión no existe.',
          status: 404,
          error: 'NotFound',
        ),
      );

      expect(
        () => repository.revokeSession(sesionId),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('cambiar contraseña (04 §4.3)', () {
    test('envía currentPassword y newPassword', () async {
      http.on('PUT', '/users/change-password', {
        'message': 'Contraseña actualizada.',
      });

      await repository.changePassword(actual: 'Vieja1!', nueva: 'Nueva23#');

      final enviado = http.lastRequest().data as Map<String, dynamic>;
      expect(enviado['currentPassword'], 'Vieja1!');
      expect(enviado['newPassword'], 'Nueva23#');
    });

    test(
      'la contraseña actual incorrecta llega como ValidationException',
      () async {
        http.onError(
          'PUT',
          '/users/change-password',
          statusCode: 400,
          body: errorBodyJson('La contraseña actual es incorrecta.'),
        );

        await expectLater(
          repository.changePassword(actual: 'Mal1!', nueva: 'Nueva23#'),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.userMessage,
              'userMessage',
              'La contraseña actual es incorrecta.',
            ),
          ),
        );
      },
    );
  });
}
