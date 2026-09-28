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
  late InMemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    storage = InMemoryTokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(ApiClient(dio: dio)),
      storage,
    );
  });

  group('forgotPassword (04 §3.5)', () {
    test('envía el email al endpoint de recuperación', () async {
      http.on('POST', '/auth/forgot-password', {
        'message': 'Si el correo existe, recibirás un enlace.',
      });

      await repository.forgotPassword(email: 'carlos@quickbite.mx');

      expect(http.lastRequest().path, '/auth/forgot-password');
      expect(http.lastRequest().data, {'email': 'carlos@quickbite.mx'});
    });

    test('no toca la sesión: recuperar no es autenticarse', () async {
      http.on('POST', '/auth/forgot-password', {'message': 'ok'});

      await repository.forgotPassword(email: 'carlos@quickbite.mx');

      expect(storage.saveCalls, 0);
      expect(storage.clearCalls, 0);
      expect(storage.accessToken, isNull);
    });
  });

  group('resetPassword (04 §3.6)', () {
    test('envía el token y la nueva contraseña', () async {
      http.on('POST', '/auth/reset-password', {
        'message': 'Contraseña actualizada.',
      });

      await repository.resetPassword(
        token: 'token-recuperacion',
        newPassword: 'Password1!',
      );

      expect(http.lastRequest().path, '/auth/reset-password');
      expect(http.lastRequest().data, {
        'token': 'token-recuperacion',
        'newPassword': 'Password1!',
      });
    });

    test(
      'un token inválido llega como ValidationException (04 §3.6)',
      () async {
        http.onError(
          'POST',
          '/auth/reset-password',
          statusCode: 400,
          body: errorBodyJson(
            'El enlace de recuperación es inválido o ha expirado.',
          ),
        );

        expect(
          () => repository.resetPassword(
            token: 'caducado',
            newPassword: 'Password1!',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('inválido'),
            ),
          ),
        );
      },
    );
  });
}
