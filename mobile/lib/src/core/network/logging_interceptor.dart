import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  static const _log = 'quickbite_http';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.path}',
      name: _log,
      error: options.queryParameters.isEmpty ? null : options.queryParameters,
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.path}',
      name: _log,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '✗ ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.path}',
      name: _log,
      error: err.message,
    );
    handler.next(err);
  }
}
