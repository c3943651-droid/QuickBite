sealed class AppException implements Exception {
  const AppException(this.message, {this.fieldErrors = const {}});

  final String message;
  final Map<String, List<String>> fieldErrors;

  String get userMessage;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No hay conexión con el servidor. Verifica tu red e inténtalo de nuevo.',
  ]);

  @override
  String get userMessage => message;
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'La solicitud tardó demasiado. Inténtalo de nuevo.',
  ]);

  @override
  String get userMessage => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.fieldErrors});

  @override
  String get userMessage => message;

  List<String> errorsFor(String field) => fieldErrors[field] ?? const [];
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Tu sesión expiró. Vuelve a iniciar sesión.',
  ]);

  @override
  String get userMessage => message;
}

class AccountLockedException extends AppException {
  const AccountLockedException(super.message, {this.retryAfterMinutes});

  final int? retryAfterMinutes;

  @override
  String get userMessage => message;
}

class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'No tienes permisos para realizar esta acción.',
  ]);

  @override
  String get userMessage => message;
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'No encontramos el recurso solicitado.',
  ]);

  @override
  String get userMessage => message;
}

class ConflictException extends AppException {
  const ConflictException(super.message);

  @override
  String get userMessage => message;
}

class TooManyRequestsException extends AppException {
  const TooManyRequestsException([
    super.message =
        'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
  ]);

  @override
  String get userMessage => message;
}

class ServerException extends AppException {
  const ServerException([
    super.message =
        'Ocurrió un error inesperado. Inténtalo de nuevo más tarde.',
  ]);

  @override
  String get userMessage => message;
}

class UnexpectedException extends AppException {
  const UnexpectedException([
    super.message =
        'Ocurrió un error inesperado. Inténtalo de nuevo más tarde.',
  ]);

  @override
  String get userMessage => message;
}
