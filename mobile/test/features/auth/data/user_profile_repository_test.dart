import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/auth/data/auth_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/auth/data/auth_repository_impl.dart';

import '../../../support/fake_http.dart';
import '../../../support/fake_token_storage.dart';

Dio _dioCon(FakeHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = adapter;

void main() {
  late FakeHttpAdapter http;
  late Dio dio;
  late AuthRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(ApiClient(dio: dio)),
      InMemoryTokenStorage(),
    );
  });

  group('reparto de clientes por endpoint (SCR-PROF-01)', () {
    late FakeHttpAdapter adapterPrincipal;
    late FakeHttpAdapter adapterAuth;
    late AuthRepositoryImpl conDosClientes;

    setUp(() {
      // Dos adaptadores distintos hacen visible qué cliente usa cada endpoint:
      // con el datasource mal cableado, el perfil salía por el cliente "sin
      // interceptor" y por tanto sin cabecera Authorization: el backend
      // respondía 401 y nadie limpiaba la sesión.
      adapterPrincipal = FakeHttpAdapter()
        ..on('GET', '/users/profile', {
          'id': '1',
          'nombre': 'Carlos Pérez',
          'email': 'carlos@quickbite.mx',
          'rol': 'cliente',
        })
        ..on('PUT', '/users/profile', {
          'id': '1',
          'nombre': 'Carlos P.',
          'email': 'carlos@quickbite.mx',
          'rol': 'cliente',
        });
      adapterAuth = FakeHttpAdapter()
        ..on('POST', '/auth/login', {
          'accessToken': 'a',
          'refreshToken': 'r',
          'expiresIn': 3600,
          'user': {
            'id': '1',
            'nombre': 'Carlos Pérez',
            'email': 'carlos@quickbite.mx',
            'rol': 'cliente',
          },
        });
      conDosClientes = AuthRepositoryImpl(
        AuthRemoteDataSource(
          ApiClient(dio: _dioCon(adapterPrincipal)),
          authClient: ApiClient(dio: _dioCon(adapterAuth)),
        ),
        InMemoryTokenStorage(),
      );
    });

    test('GET /users/profile sale por el cliente con interceptor', () async {
      await conDosClientes.fetchProfile();

      expect(adapterPrincipal.callsTo('GET', '/users/profile'), 1);
      expect(adapterAuth.callsTo('GET', '/users/profile'), 0);
    });

    test('PUT /users/profile sale por el cliente con interceptor', () async {
      await conDosClientes.updateProfile(nombre: 'Carlos P.');

      expect(adapterPrincipal.callsTo('PUT', '/users/profile'), 1);
      expect(adapterAuth.callsTo('PUT', '/users/profile'), 0);
    });

    test('POST /auth/login sale por el cliente sin interceptor', () async {
      await conDosClientes.login(email: 'carlos@quickbite.mx', password: 'x');

      expect(adapterAuth.callsTo('POST', '/auth/login'), 1);
      expect(adapterPrincipal.callsTo('POST', '/auth/login'), 0);
    });
  });

  group('perfil (04 §4.1/4.2)', () {
    test('GET /users/profile mapea todos los campos', () async {
      http.on('GET', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
        'telefono': '5512345678',
        'creado_en': '2026-01-15T10:00:00Z',
        'ultimo_login': '2026-09-20T08:30:00Z',
      });

      final profile = await repository.fetchProfile();

      expect(http.lastRequest().path, '/users/profile');
      expect(profile.id, '33333333-3333-3333-3333-333333333333');
      expect(profile.nombre, 'Carlos Pérez');
      expect(profile.email, 'carlos@quickbite.mx');
      expect(profile.rol, 'cliente');
      expect(profile.telefono, '5512345678');
      expect(profile.creadoEn, isNotNull);
      expect(profile.ultimoLogin, isNotNull);
    });

    test('el teléfono puede venir nulo', () async {
      http.on('GET', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
        'telefono': null,
      });

      expect((await repository.fetchProfile()).telefono, isNull);
    });

    test('PUT /users/profile envía solo los campos editables', () async {
      http.on('PUT', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': 'Carlos P.',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
        'telefono': '5512345678',
      });

      await repository.updateProfile(
        nombre: 'Carlos P.',
        telefono: '5512345678',
      );

      expect(http.lastRequest().method, 'PUT');
      expect(http.lastRequest().data, {
        'nombre': 'Carlos P.',
        'telefono': '5512345678',
      });
    });

    test(
      'un nombre vacío se envía como null para no romper el contrato',
      () async {
        http.on('PUT', '/users/profile', {
          'id': '33333333-3333-3333-3333-333333333333',
          'nombre': 'Carlos',
          'email': 'carlos@quickbite.mx',
          'rol': 'cliente',
        });

        await repository.updateProfile(nombre: '', telefono: null);

        expect(http.lastRequest().data, {'nombre': null, 'telefono': null});
      },
    );

    test('un nombre nulo no rompe la pantalla de perfil', () async {
      // La columna `nombre` del backend no es NOT NULL en todos los caminos de
      // alta: si llega null, el `as String`generated reventaba y el perfil
      // entero se quedaba en error.
      http.on('GET', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': null,
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
        'telefono': null,
      });

      final profile = await repository.fetchProfile();

      expect(profile.nombre, isNotNull);
      expect(profile.nombre, isEmpty);
      expect(profile.email, 'carlos@quickbite.mx');
    });

    test(
      'si falta el rol completo, el resto del perfil sigue siendo legible',
      () async {
        http.on('GET', '/users/profile', {
          'id': '33333333-3333-3333-3333-333333333333',
          'nombre': 'Carlos Pérez',
          'email': 'carlos@quickbite.mx',
        });

        final profile = await repository.fetchProfile();

        expect(profile.nombre, 'Carlos Pérez');
        expect(profile.rol, isEmpty);
      },
    );

    test('una fecha de alta mal formada no tira el perfil entero', () async {
      http.on('GET', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
        'creado_en': 'no-es-una-fecha',
        'ultimo_login': '',
      });

      final profile = await repository.fetchProfile();

      expect(profile.creadoEn, isNull);
      expect(profile.ultimoLogin, isNull);
      expect(profile.nombre, 'Carlos Pérez');
    });

    test('un id numérico se acepta sin romper el mapeo', () async {
      http.on('GET', '/users/profile', {
        'id': 42,
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
      });

      expect((await repository.fetchProfile()).id, '42');
    });

    test('un 401 al leer el perfil lanza UnauthorizedException', () async {
      http.onError('GET', '/users/profile', statusCode: 401, body: {});

      expect(repository.fetchProfile, throwsA(isA<UnauthorizedException>()));
    });
  });
}
