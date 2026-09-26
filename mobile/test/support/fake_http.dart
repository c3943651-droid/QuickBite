import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adapter HTTP falso: enruta por método + path y devuelve JSON predefinido.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter();

  final List<RequestOptions> requests = [];
  final Map<String, FakeRoute> _routes = {};

  int closeCalls = 0;

  void on(String method, String path, Object body, {int statusCode = 200}) {
    _routes[_key(method, path)] = FakeRoute(body: body, statusCode: statusCode);
  }

  void onError(
    String method,
    String path, {
    int statusCode = 400,
    Object? body,
  }) {
    _routes[_key(method, path)] = FakeRoute(
      body: body,
      statusCode: statusCode,
      isError: true,
    );
  }

  RequestOptions lastRequest() => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = _routes[_key(options.method, options.path)];
    if (route == null) {
      return ResponseBody.fromString(
        jsonEncode({
          'message': 'Ruta no simulada: ${options.method} ${options.path}',
        }),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(route.body),
      route.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {
    closeCalls++;
  }

  String _key(String method, String path) => '$method ${_stripQuery(path)}';

  String _stripQuery(String path) {
    final index = path.indexOf('?');
    return index == -1 ? path : path.substring(0, index);
  }
}

class FakeRoute {
  const FakeRoute({
    required this.body,
    required this.statusCode,
    this.isError = false,
  });

  final Object? body;
  final int statusCode;
  final bool isError;
}

Map<String, dynamic> categoryJson({
  String id = '22222222-2222-2222-2222-222222222222',
  String nombre = 'Tacos',
  int orden = 1,
  String? icon = 'local_dining',
}) {
  return {
    'id': id,
    'nombre': nombre,
    'descripcion': 'Comida mexicana',
    'orden': orden,
    'activo': true,
    'icon': icon,
  };
}

Map<String, dynamic> productJson({
  String id = '11111111-1111-1111-1111-111111111111',
  String nombre = 'Tacos al pastor',
  double precio = 85.50,
  bool disponible = true,
  int? stock = 20,
}) {
  return {
    'id': id,
    'nombre': nombre,
    'descripcion': 'Tres tacos de pastor',
    'precio': precio,
    'imagenUrl': 'https://img.example.com/pastor.png',
    'disponible': disponible,
    'categoria': categoryJson(),
    'stock': stock,
    'stockMinimo': 5,
  };
}

Map<String, dynamic> pagedResponseJson({
  required List<Map<String, dynamic>> data,
  int page = 1,
  int limit = 12,
  int total = 12,
}) {
  return {
    'data': data,
    'total': total,
    'page': page,
    'limit': limit,
    'totalPages': (total / limit).ceil(),
  };
}

Map<String, dynamic> authResponseJson({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  int expiresIn = 3600,
  String email = 'carlos@quickbite.mx',
  String rol = 'cliente',
}) {
  return {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'tokenType': 'Bearer',
    'user': {
      'id': '33333333-3333-3333-3333-333333333333',
      'nombre': 'Carlos Pérez',
      'email': email,
      'rol': rol,
    },
  };
}
