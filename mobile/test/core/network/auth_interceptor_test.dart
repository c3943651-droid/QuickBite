import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/auth_interceptor.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({
    this.accessToken,
    this.refreshToken = 'refresh-1',
    this.expiresIn = 3600,
  });

  String? accessToken;
  String? refreshToken;
  int expiresIn;
  int clearCalls = 0;
  int saveCalls = 0;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    clearCalls++;
  }

  @override
  Future<StoredSession?> read() async {
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    return StoredSession(
      accessToken: accessToken!,
      refreshToken: refreshToken!,
      expiresIn: expiresIn,
    );
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> save(StoredSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
    expiresIn = session.expiresIn;
    saveCalls++;
  }
}

/// Server simulado: las primeras [unauthorizedTimes] peticiones de cada ruta
/// responden 401; después responde 200. Registra los headers recibidos.
class ScriptedServer implements HttpClientAdapter {
  ScriptedServer({this.unauthorizedTimes = 1});

  final int unauthorizedTimes;
  final Map<String, int> _attempts = {};
  final List<String?> receivedAuthorization = [];

  int get totalRequests => _attempts.values.fold(0, (a, b) => a + b);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final attempt = (_attempts[key] ?? 0) + 1;
    _attempts[key] = attempt;
    receivedAuthorization.add(options.headers['Authorization'] as String?);

    if (attempt <= unauthorizedTimes) {
      return ResponseBody.fromString(
        '{"message":"Token expirado","status":401}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio buildDio({
  required TokenStorage storage,
  required Future<StoredSession?> Function() onRefresh,
  ScriptedServer? server,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..httpClientAdapter = server ?? ScriptedServer();
  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: storage,
      onRefresh: onRefresh,
      dioProvider: () => dio,
    ),
  );
  return dio;
}

void main() {
  group('AuthInterceptor.onRequest', () {
    test('inyecta Authorization Bearer cuando hay access token', () async {
      final storage = FakeTokenStorage(accessToken: 'token-abc');
      final server = ScriptedServer(unauthorizedTimes: 0);
      final dio = buildDio(
        storage: storage,
        onRefresh: () async => null,
        server: server,
      );

      await dio.get<void>('/products');

      expect(server.receivedAuthorization.single, 'Bearer token-abc');
    });

    test('no inyecta Authorization sin sesión', () async {
      final storage = FakeTokenStorage(accessToken: null);
      final server = ScriptedServer(unauthorizedTimes: 0);
      final dio = buildDio(
        storage: storage,
        onRefresh: () async => null,
        server: server,
      );

      await dio.get<void>('/products');

      expect(server.receivedAuthorization.single, isNull);
    });
  });

  group('AuthInterceptor.onError', () {
    test('renueva el token y reintenta una sola vez ante 401', () async {
      final storage = FakeTokenStorage(accessToken: 'expired-token');
      final server = ScriptedServer();
      var refreshCalls = 0;
      final dio = buildDio(
        storage: storage,
        server: server,
        onRefresh: () async {
          refreshCalls++;
          return const StoredSession(
            accessToken: 'fresh-token',
            refreshToken: 'refresh-2',
            expiresIn: 3600,
          );
        },
      );

      final response = await dio.get<String>('/products');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(
        server.totalRequests,
        2,
        reason: 'debe reintentar exactamente una vez',
      );
      expect(server.receivedAuthorization, [
        'Bearer expired-token',
        'Bearer fresh-token',
      ], reason: 'el reintento debe llevar el token renovado');
    });

    test('propaga el error si el reintento también falla con 401', () async {
      final storage = FakeTokenStorage(accessToken: 'expired-token');
      final server = ScriptedServer(unauthorizedTimes: 5);
      final dio = buildDio(
        storage: storage,
        server: server,
        onRefresh: () async => const StoredSession(
          accessToken: 'fresh-token',
          refreshToken: 'refresh-2',
          expiresIn: 3600,
        ),
      );

      await expectLater(
        dio.get<String>('/products'),
        throwsA(isA<DioException>()),
      );
      expect(
        storage.clearCalls,
        1,
        reason: 'un 401 tras reintentar debe cerrar la sesión',
      );
    });

    test('deduplica refreshes concurrentes en una sola llamada', () async {
      final storage = FakeTokenStorage(accessToken: 'expired-token');
      final server = ScriptedServer();
      var refreshCalls = 0;
      final gate = Completer<void>();

      final dio = buildDio(
        storage: storage,
        server: server,
        onRefresh: () async {
          refreshCalls++;
          await gate.future;
          return const StoredSession(
            accessToken: 'fresh-token',
            refreshToken: 'refresh-2',
            expiresIn: 3600,
          );
        },
      );

      final futures = [
        dio.get<String>('/products'),
        dio.get<String>('/categories'),
        dio.get<String>('/categories'),
      ];
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.complete();
      await Future.wait(futures);

      expect(
        refreshCalls,
        1,
        reason: 'tres 401 concurrentes deben producir un solo refresh',
      );
    });

    test('limpia el almacenamiento si el refresh falla', () async {
      final storage = FakeTokenStorage(accessToken: 'expired-token');
      final dio = buildDio(
        storage: storage,
        onRefresh: () async => throw StateError('refresh rechazado'),
      );

      await expectLater(
        dio.get<String>('/products'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<UnauthorizedException>(),
          ),
        ),
      );
      expect(storage.clearCalls, greaterThanOrEqualTo(1));
      expect(storage.accessToken, isNull);
    });

    test('no intenta refresh sin sesión almacenada', () async {
      final storage = FakeTokenStorage(accessToken: null, refreshToken: null);
      var refreshCalls = 0;
      final dio = buildDio(
        storage: storage,
        onRefresh: () async {
          refreshCalls++;
          return null;
        },
      );

      await expectLater(
        dio.get<String>('/products'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<UnauthorizedException>(),
          ),
        ),
      );
      expect(refreshCalls, 0);
      expect(storage.clearCalls, 1);
    });

    test('no intenta refresh en /auth/login', () async {
      final storage = FakeTokenStorage(accessToken: 'expired-token');
      var refreshCalls = 0;
      final dio = buildDio(
        storage: storage,
        onRefresh: () async {
          refreshCalls++;
          return const StoredSession(
            accessToken: 'fresh',
            refreshToken: 'r',
            expiresIn: 1,
          );
        },
      );

      await expectLater(
        dio.post<String>('/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(
        refreshCalls,
        0,
        reason: 'renovar en el login crearía un bucle infinito',
      );
    });

    test('no intenta refresh en /auth/refresh', () async {
      final storage = FakeTokenStorage(accessToken: 'expired-token');
      var refreshCalls = 0;
      final dio = buildDio(
        storage: storage,
        onRefresh: () async {
          refreshCalls++;
          return const StoredSession(
            accessToken: 'fresh',
            refreshToken: 'r',
            expiresIn: 1,
          );
        },
      );

      await expectLater(
        dio.post<String>('/auth/refresh'),
        throwsA(isA<DioException>()),
      );
      expect(
        refreshCalls,
        0,
        reason: 'renovar dentro del refresh crearía un bucle infinito',
      );
    });
  });
}
