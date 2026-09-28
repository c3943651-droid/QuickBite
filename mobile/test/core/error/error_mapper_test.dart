import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/error/error_mapper.dart';
import 'package:quickbite_mobile/src/features/catalog/data/dtos/catalog_dtos.dart';

void main() {
  const mapper = ErrorMapper();

  group('ErrorMapper.fromStatusCode', () {
    test(
      '400 con details produce ValidationException con errores por campo',
      () {
        final exception = mapper.fromStatusCode(400, {
          'timestamp': '2026-09-25T10:00:00Z',
          'status': 400,
          'error': 'Validation Error',
          'message': 'Datos inválidos.',
          'path': '/api/v1/auth/register',
          'details': {
            'Password': ['La contraseña debe tener al menos 8 caracteres.'],
            'Email': ['Formato de email inválido.'],
          },
        });

        expect(exception, isA<ValidationException>());
        final validation = exception as ValidationException;
        expect(validation.errorsFor('Password'), [
          'La contraseña debe tener al menos 8 caracteres.',
        ]);
        expect(validation.errorsFor('Email'), isNotEmpty);
        expect(
          validation.fieldErrors.keys,
          containsAll(<String>['Password', 'Email']),
        );
      },
    );

    test('400 sin details cae en mensaje genérico', () {
      final exception = mapper.fromStatusCode(400, null);
      expect(exception, isA<ValidationException>());
      expect(exception.fieldErrors, isEmpty);
    });

    test('401 produce UnauthorizedException', () {
      expect(mapper.fromStatusCode(401, null), isA<UnauthorizedException>());
    });

    test('403 con mensaje de bloqueo produce AccountLockedException', () {
      final exception = mapper.fromStatusCode(403, {
        'message': 'La cuenta está bloqueada por 15 minutos.',
      });
      expect(exception, isA<AccountLockedException>());
    });

    test('403 sin bloqueo produce ForbiddenException', () {
      expect(
        mapper.fromStatusCode(403, {'message': 'Permisos insuficientes.'}),
        isA<ForbiddenException>(),
      );
    });

    test('404 produce NotFoundException', () {
      expect(mapper.fromStatusCode(404, null), isA<NotFoundException>());
    });

    test('409 revela el email duplicado', () {
      final exception = mapper.fromStatusCode(409, {
        'message': 'El correo ya está registrado',
      });
      expect(exception, isA<ConflictException>());
      expect(exception.message, 'El correo ya está registrado');
    });

    test('429 produce TooManyRequestsException', () {
      expect(mapper.fromStatusCode(429, null), isA<TooManyRequestsException>());
    });

    test('5xx produce ServerException con mensaje genérico', () {
      final exception = mapper.fromStatusCode(500, {
        'message': 'Stack trace interno filtrado',
      });
      expect(exception, isA<ServerException>());
      expect(exception.userMessage, isNot(contains('Stack trace')));
    });
  });

  group('PagedResponseDto', () {
    test('deserializa el envelope real de la API', () {
      final page = PagedResponseDto<ProductDto>.fromJson({
        'data': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'nombre': 'Tacos al pastor',
            'descripcion': 'Tres tacos',
            'precio': 85.50,
            'imagenUrl': 'https://img.example.com/pastor.png',
            'disponible': true,
            'categoria': {
              'id': '22222222-2222-2222-2222-222222222222',
              'nombre': 'Tacos',
              'descripcion': null,
              'orden': 1,
              'activo': true,
              'icon': 'local_dining',
            },
            'stock': 20,
            'stockMinimo': 5,
          },
        ],
        'total': 1,
        'page': 1,
        'limit': 12,
        'totalPages': 1,
      }, ProductDto.fromJson);

      expect(page.data, hasLength(1));
      final product = page.data.first;
      expect(product.nombre, 'Tacos al pastor');
      expect(product.precio, 85.50);
      expect(product.disponible, isTrue);
      expect(product.categoria?.nombre, 'Tacos');
      expect(page.hasMore, isFalse);
    });

    test('hasMore es true cuando page es menor que totalPages', () {
      final page = PagedResponseDto<ProductDto>.fromJson({
        'data': <dynamic>[],
        'total': 30,
        'page': 1,
        'limit': 12,
        'totalPages': 3,
      }, ProductDto.fromJson);

      expect(page.hasMore, isTrue);
    });

    test('tolera envelope sin data', () {
      final page = PagedResponseDto<ProductDto>.fromJson({
        'total': 0,
      }, ProductDto.fromJson);
      expect(page.data, isEmpty);
      expect(page.page, 1);
    });
  });
}
