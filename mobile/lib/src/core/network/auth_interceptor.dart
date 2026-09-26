import 'dart:async';

import 'package:dio/dio.dart';

import '../error/error_mapper.dart';
import '../session/token_storage.dart';

typedef RefreshCallback = Future<StoredSession?> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.onRefresh,
    required this.dioProvider,
    ErrorMapper? errorMapper,
  }) : _errorMapper = errorMapper ?? const ErrorMapper();
  final TokenStorage tokenStorage;
  final RefreshCallback onRefresh;
  final Dio Function() dioProvider;
  final ErrorMapper _errorMapper;

  static const _retriedFlag = 'quickbite_retried';

  Future<StoredSession?>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final alreadyRetried = options.extra[_retriedFlag] == true;
    if (alreadyRetried) {
      return handler.next(options);
    }

    final token = await tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isAuthEndpoint =
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh');

    if (!isUnauthorized ||
        isAuthEndpoint ||
        options.extra[_retriedFlag] == true) {
      return handler.next(err);
    }

    final session = await _refresh();
    if (session == null) {
      await tokenStorage.clear();
      return handler.next(err.copyWith(error: _errorMapper.map(err)));
    }

    options.extra[_retriedFlag] = true;
    options.headers['Authorization'] = 'Bearer ${session.accessToken}';

    try {
      final response = await _retry(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await tokenStorage.clear();
      }
      return handler.next(retryError);
    }
  }

  Future<StoredSession?> _refresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<StoredSession?> _doRefresh() async {
    final stored = await tokenStorage.read();
    if (stored == null) {
      return null;
    }
    try {
      return await onRefresh();
    } on Object {
      return null;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) {
    return dioProvider().fetch<dynamic>(options);
  }
}
