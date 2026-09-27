import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adapter HTTP falso: enruta por método + path y devuelve JSON predefinido.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter();

  final List<RecordedRequest> requests = [];
  final Map<String, FakeRoute> _routes = {};
  final Map<String, int> _attempts = {};

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

  /// Registra una respuesta distinta por intento: `responses.first` para la
  /// primera llamada, `responses.last` de forma indefinida. Permite simular
  /// el 401 inicial seguido del reintento con éxito sobre la misma ruta.
  void onSequence(String method, String path, List<FakeRoute> responses) {
    assert(
      responses.isNotEmpty,
      'la secuencia necesita al menos una respuesta',
    );
    _routes[_key(method, path)] = FakeRoute(sequence: responses);
  }

  /// Número de llamadas recibidas para un método + ruta.
  int callsTo(String method, String path) => _attempts[_key(method, path)] ?? 0;

  /// Todas las peticiones recibidas para un método + ruta, en orden.
  List<RecordedRequest> requestsTo(String method, String path) =>
      requests.where((r) => r.key == _key(method, path)).toList();

  RecordedRequest lastRequest() => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Se guarda una instantánea: el interceptor reutiliza y muta el mismo
    // `RequestOptions` al reintentar (nuevo header Authorization, flag de
    // reintento), así que guardar la referencia perdería el estado original.
    requests.add(RecordedRequest.of(options));
    final key = _key(options.method, options.path);
    final attempt = (_attempts[key] ?? 0) + 1;
    _attempts[key] = attempt;

    final route = _routes[key];
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
    final resolved = route.sequence == null
        ? route
        : route.sequence![attempt.clamp(1, route.sequence!.length) - 1];
    return ResponseBody.fromString(
      jsonEncode(resolved.body),
      resolved.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {
    closeCalls++;
  }

  String _key(String method, String path) => '$method ${stripQuery(path)}';
}

String stripQuery(String path) {
  final index = path.indexOf('?');
  return index == -1 ? path : path.substring(0, index);
}

/// Copia inmutable de una petición recibida, para que las aserciones puedan
/// distinguir la petición original de su reintento.
class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.path,
    required this.data,
    required this.queryParameters,
    required this.headers,
  });

  factory RecordedRequest.of(RequestOptions options) {
    return RecordedRequest(
      method: options.method,
      path: options.path,
      data: options.data,
      queryParameters: Map<String, dynamic>.of(options.queryParameters),
      headers: Map<String, dynamic>.of(options.headers),
    );
  }

  final String method;
  final String path;
  final Object? data;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> headers;

  String get key => '$method ${stripQuery(path)}';
}

class FakeRoute {
  const FakeRoute({
    this.body,
    this.statusCode = 200,
    this.isError = false,
    this.sequence,
  });

  final Object? body;
  final int statusCode;
  final bool isError;
  final List<FakeRoute>? sequence;
}

FakeRoute fakeOk(Object body) => FakeRoute(body: body, statusCode: 200);

FakeRoute fakeStatus(int statusCode, [Object? body]) =>
    FakeRoute(body: body, statusCode: statusCode, isError: statusCode >= 400);

/// Cuerpo de error con la envoltura que emite la API (documento 04 §2.5).
Map<String, dynamic> errorBodyJson(
  String message, {
  int status = 400,
  String error = 'BadRequest',
}) {
  return {
    'timestamp': '2026-09-26T12:00:00Z',
    'status': status,
    'error': error,
    'message': message,
    'path': '/api/v1',
  };
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

Map<String, dynamic> addressJson({
  String id = '55555555-5555-5555-5555-555555555555',
  String alias = 'Casa',
  String calle = 'Av. Insurgentes',
  String numero = '123',
  String referencia = 'Portón azul',
  String ciudad = 'CDMX',
  double latitud = 19.4326,
  double longitud = -99.1332,
  bool esPredeterminada = true,
}) {
  return {
    'id': id,
    'alias': alias,
    'calle': calle,
    'numero': numero,
    'referencia': referencia,
    'ciudad': ciudad,
    'latitud': latitud,
    'longitud': longitud,
    'es_predeterminada': esPredeterminada,
    'creado_en': '2026-02-01T12:00:00Z',
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
