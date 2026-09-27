import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';

import '../../../support/fake_http.dart';
import '../../../support/fake_token_storage.dart';

/// Cubre H0.1 sobre el cableado real de providers (`dioProvider` +
/// `authRepositoryProvider` + `tokenStorageProvider`), no sobre un
/// `onRefresh` inyectado a mano: aquí se comprueba que la renovación
/// realmente viaja por HTTP y que los tokens nuevos quedan persistidos.
const _config = AppConfig(
  apiBaseUrl: 'https://api.test/api/v1',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 10),
);

const _userJson = {
  'id': '1',
  'nombre': 'Carlos Pérez',
  'email': 'carlos@quickbite.mx',
  'rol': 'cliente',
};

Map<String, dynamic> _unauthorized() => errorBodyJson(
  'El token es inválido o expiró',
  status: 401,
  error: 'Unauthorized',
);

ProviderContainer _build(
  InMemoryTokenStorage storage,
  FakeHttpAdapter adapter,
) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(_config),
      tokenStorageProvider.overrideWithValue(storage),
      // Un solo adapter para el cliente principal y el de autenticación, de
      // modo que el POST /auth/refresh también queda registrado.
      httpClientAdapterProvider.overrideWithValue(adapter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Deja `sessionProvider` con una sesión viva (GET /users/profile responde).
Future<void> _startSession(ProviderContainer container) async {
  await container.read(sessionProvider.future);
}

void main() {
  group('H0.1 — renovación transparente de sesión', () {
    test(
      'un 401 dispara POST /auth/refresh con el refresh token guardado',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
        );
        final adapter = FakeHttpAdapter()
          ..onSequence('GET', '/products', [
            fakeStatus(401, _unauthorized()),
            fakeOk(<String, dynamic>{}),
          ])
          ..on('POST', '/auth/refresh', const {
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
            'expiresIn': 3600,
          });
        final container = _build(storage, adapter);

        await container
            .read(apiClientProvider)
            .get('/products')
            .then((_) {}, onError: (_, _) {});

        expect(adapter.callsTo('POST', '/auth/refresh'), 1);
        final body = adapter.requestsTo('POST', '/auth/refresh').single.data;
        expect(body, {'refreshToken': 'refresh-1'});
      },
    );

    test(
      'el reintento envía el Bearer nuevo y la llamada original se repite',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
        );
        final adapter = FakeHttpAdapter()
          ..onSequence('GET', '/products', [
            fakeStatus(401, _unauthorized()),
            fakeOk(<String, dynamic>{}),
          ])
          ..on('POST', '/auth/refresh', const {
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
            'expiresIn': 3600,
          });
        final container = _build(storage, adapter);

        final response = await container
            .read(apiClientProvider)
            .get('/products');

        expect(response.statusCode, 200);
        expect(adapter.callsTo('GET', '/products'), 2);
        final getRequests = adapter.requestsTo('GET', '/products');
        expect(getRequests.first.headers['Authorization'], 'Bearer access-1');
        expect(getRequests.last.headers['Authorization'], 'Bearer access-2');
      },
    );

    test('la renovación persiste los tokens nuevos', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      final adapter = FakeHttpAdapter()
        ..onSequence('GET', '/products', [
          fakeStatus(401, _unauthorized()),
          fakeOk(<String, dynamic>{}),
        ])
        ..on('POST', '/auth/refresh', const {
          'accessToken': 'access-2',
          'refreshToken': 'refresh-2',
          'expiresIn': 3600,
        });
      final container = _build(storage, adapter);

      await container.read(apiClientProvider).get('/products');

      expect(storage.accessToken, 'access-2');
      expect(storage.refreshToken, 'refresh-2');
      expect(storage.saveCalls, 1);
      expect(storage.clearCalls, 0);
    });

    test('sin refresh token guardado no intenta renovar', () async {
      final storage = InMemoryTokenStorage();
      final adapter = FakeHttpAdapter()
        ..on('GET', '/products', _unauthorized(), statusCode: 401);
      final container = _build(storage, adapter);

      await expectLater(
        container.read(apiClientProvider).get('/products'),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(adapter.callsTo('POST', '/auth/refresh'), 0);
      expect(adapter.callsTo('GET', '/products'), 1);
    });
  });

  group('H0.1 — sesión irreparablemente expirada', () {
    late InMemoryTokenStorage storage;
    late FakeHttpAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      storage = InMemoryTokenStorage(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      adapter = FakeHttpAdapter()
        ..on('GET', '/users/profile', _userJson)
        ..on('GET', '/products', _unauthorized(), statusCode: 401)
        ..on('GET', '/categories', const <String, dynamic>{})
        ..on('POST', '/auth/refresh', _unauthorized(), statusCode: 401);
      container = _build(storage, adapter);
    });

    test(
      'limpia los tokens guardados cuando la renovación devuelve 401',
      () async {
        await _startSession(container);

        await expectLater(
          container.read(apiClientProvider).get('/products'),
          throwsA(isA<UnauthorizedException>()),
        );

        expect(storage.clearCalls, 1);
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
        expect(adapter.callsTo('POST', '/auth/refresh'), 1);
      },
    );

    test(
      'publica la sesión como nula para que el router redirija a /login',
      () async {
        await _startSession(container);
        expect(container.read(sessionProvider).requireValue, isNotNull);

        await container
            .read(apiClientProvider)
            .get('/products')
            .then((_) {}, onError: (_, _) {});

        expect(container.read(sessionProvider).requireValue, isNull);
      },
    );

    test('no intenta renovar más de una vez por petición fallida', () async {
      await _startSession(container);

      await container
          .read(apiClientProvider)
          .get('/products')
          .then((_) {}, onError: (_, _) {});

      expect(adapter.callsTo('GET', '/products'), 1);
      expect(adapter.callsTo('POST', '/auth/refresh'), 1);
    });
  });
}
