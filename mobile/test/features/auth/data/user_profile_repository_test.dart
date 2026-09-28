import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/auth/data/auth_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/auth/data/auth_repository_impl.dart';

import '../../../support/fake_http.dart';
import '../../../support/fake_token_storage.dart';

void main() {
  late FakeHttpAdapter http;
  late AuthRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(ApiClient(dio: dio)),
      InMemoryTokenStorage(),
    );
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

    test('un 401 al leer el perfil lanza UnauthorizedException', () async {
      http.onError('GET', '/users/profile', statusCode: 401, body: {});

      expect(repository.fetchProfile, throwsA(isA<UnauthorizedException>()));
    });
  });
}
