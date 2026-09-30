import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/data/auth_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/auth/data/auth_repository_impl.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';

import '../../../support/fake_http.dart';

class MemoryTokenStorage implements TokenStorage {
  StoredSession? session;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    session = null;
    clearCalls++;
  }

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<String?> readAccessToken() async => session?.accessToken;

  @override
  Future<void> save(StoredSession value) async => session = value;
}

void main() {
  late FakeHttpAdapter http;
  late MemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    storage = MemoryTokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(ApiClient(dio: dio)),
      storage,
    );
  });

  group('login', () {
    test('mapea la respuesta a AuthSession', () async {
      http.on('POST', '/auth/login', authResponseJson());

      final session = await repository.login(
        email: 'carlos@quickbite.mx',
        password: 'Password1!',
      );

      expect(session.tokens.accessToken, 'access-1');
      expect(session.tokens.refreshToken, 'refresh-1');
      expect(session.tokens.expiresIn, 3600);
      expect(session.user.nombre, 'Carlos Pérez');
      expect(session.user.email, 'carlos@quickbite.mx');
      expect(session.user.isCliente, isTrue);
    });

    test('envía email y password en el cuerpo', () async {
      http.on('POST', '/auth/login', authResponseJson());

      await repository.login(
        email: 'carlos@quickbite.mx',
        password: 'Password1!',
      );

      expect(http.lastRequest().data, {
        'email': 'carlos@quickbite.mx',
        'password': 'Password1!',
      });
    });

    test('no persiste la sesión automáticamente', () async {
      http.on('POST', '/auth/login', authResponseJson());

      await repository.login(
        email: 'carlos@quickbite.mx',
        password: 'Password1!',
      );

      expect(storage.session, isNull);
    });
  });

  group('register', () {
    test('envía todos los campos y no guarda sesión', () async {
      http.on('POST', '/auth/register', {
        'message': 'Usuario registrado',
      }, statusCode: 201);

      await repository.register(
        nombre: 'Carlos Pérez',
        email: 'carlos@quickbite.mx',
        password: 'Password1!',
        telefono: '55 1234 5678',
        rol: 'repartidor',
      );

      expect(http.lastRequest().data, {
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'password': 'Password1!',
        'telefono': '55 1234 5678',
        'rol': 'repartidor',
      });
      expect(storage.session, isNull);
    });
  });

  group('refresh', () {
    test('devuelve tokens renovados', () async {
      http.on('POST', '/auth/refresh', {
        'accessToken': 'access-2',
        'refreshToken': 'refresh-2',
        'expiresIn': 7200,
        'tokenType': 'Bearer',
      });

      final tokens = await repository.refresh(refreshToken: 'refresh-1');

      expect(tokens.accessToken, 'access-2');
      expect(tokens.refreshToken, 'refresh-2');
      expect(tokens.expiresIn, 7200);
    });
  });

  group('logout', () {
    test('limpia el almacenamiento local', () async {
      storage.session = const StoredSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 1,
      );
      http.on('POST', '/auth/logout', {'message': 'Sesión cerrada'});

      await repository.logout(refreshToken: 'refresh-1');

      expect(http.lastRequest().data, {'refreshToken': 'refresh-1'});
      expect(storage.session, isNull);
    });

    test('limpia el almacenamiento local aunque el backend falle', () async {
      storage.session = const StoredSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 1,
      );
      http.onError(
        'POST',
        '/auth/logout',
        statusCode: 500,
        body: {'message': 'Error interno'},
      );

      await expectLater(
        repository.logout(refreshToken: 'refresh-1'),
        throwsA(isA<Exception>()),
      );
      expect(
        storage.session,
        isNull,
        reason: 'el logout local debe completarse aunque el backend falle',
      );
    });
  });

  group('restoreSession / persistSession', () {
    test('persiste y restaura los tokens', () async {
      const session = AuthSession(
        tokens: AuthTokens(
          accessToken: 'access-9',
          refreshToken: 'refresh-9',
          expiresIn: 3600,
        ),
        user: AuthUser(
          id: '1',
          nombre: 'Carlos',
          email: 'c@q.mx',
          rol: 'cliente',
        ),
      );

      await repository.persistSession(session);
      final restored = await repository.restoreSession();

      expect(restored?.accessToken, 'access-9');
      expect(restored?.refreshToken, 'refresh-9');
      expect(restored?.expiresIn, 3600);
    });

    test('devuelve null sin sesión guardada', () async {
      expect(await repository.restoreSession(), isNull);
    });
  });
}
