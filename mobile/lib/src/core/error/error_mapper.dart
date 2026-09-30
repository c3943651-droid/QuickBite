import 'package:dio/dio.dart';

import 'api_error_response.dart';
import 'app_exception.dart';

class ErrorMapper {
  const ErrorMapper();

  AppException map(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      return _fromDio(error);
    }
    if (error is FormatException) {
      return const UnexpectedException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }
    return const UnexpectedException();
  }

  AppException fromStatusCode(int statusCode, Object? data) {
    final envelope = data == null ? null : _tryParse(_asMap(data));
    final message = envelope?.message;
    final details = envelope?.details ?? const <String, List<String>>{};

    return switch (statusCode) {
      400 => ValidationException(
        message ?? 'Los datos enviados no son válidos.',
        fieldErrors: details,
      ),
      401 => const UnauthorizedException(),
      403 => _forbidden(message),
      404 => const NotFoundException(),
      409 => ConflictException(message ?? 'El recurso ya existe.'),
      429 => const TooManyRequestsException(),
      >= 500 => const ServerException(),
      _ => UnexpectedException(message ?? 'Ocurrió un error inesperado.'),
    };
  }

  AppException _fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const NetworkException('La solicitud fue cancelada.');
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'No se pudo verificar la conexión segura con el servidor.',
        );
      case DioExceptionType.badResponse:
        return fromStatusCode(
          error.response?.statusCode ?? 500,
          error.response?.data,
        );
      case DioExceptionType.unknown:
        return error.error is FormatException
            ? const UnexpectedException(
                'La respuesta del servidor no tiene el formato esperado.',
              )
            : const NetworkException();
    }
  }

  AppException _forbidden(String? message) {
    if (message != null && message.toLowerCase().contains('bloquead')) {
      return AccountLockedException(message);
    }
    return ForbiddenException(
      message ?? 'No tienes permisos para realizar esta acción.',
    );
  }

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  ApiErrorResponse? _tryParse(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    try {
      return ApiErrorResponse.fromJson(json);
    } on Object {
      return null;
    }
  }
}
