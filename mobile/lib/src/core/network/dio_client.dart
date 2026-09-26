import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/error_mapper.dart';
import '../session/token_storage.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

typedef SessionRefreshCallback = Future<StoredSession?> Function();

class DioClient {
  DioClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    SessionRefreshCallback? onRefresh,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: config.connectTimeout,
           receiveTimeout: config.receiveTimeout,
           headers: const {
             'Content-Type': 'application/json',
             'Accept': 'application/json',
           },
         ),
       ) {
    if (config.isDebug) {
      dio.interceptors.add(LoggingInterceptor());
    }
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: onRefresh ?? _unsupportedRefresh,
        dioProvider: () => dio,
      ),
    );
  }

  final Dio dio;

  static Future<StoredSession?> _unsupportedRefresh() async => null;
}

class ApiClient {
  ApiClient({required this.dio, ErrorMapper? errorMapper})
    : errorMapper = errorMapper ?? const ErrorMapper();

  final Dio dio;
  final ErrorMapper errorMapper;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _guard(
      () => dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _guard(() => dio.post<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {Object? data}) {
    return _guard(() => dio.patch<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) {
    return _guard(() => dio.delete<dynamic>(path));
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on Object catch (error) {
      throw errorMapper.map(error);
    }
  }
}
