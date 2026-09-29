import '../../../core/network/dio_client.dart';
import '../domain/disponibilidad.dart';
import 'dtos/delivery_dtos.dart';

class DeliveryRemoteDataSource {
  const DeliveryRemoteDataSource(this._client);

  final ApiClient _client;

  /// `GET /delivery/available` devuelve el array plano, sin envoltorio.
  Future<List<PedidoEntregaDto>> listarDisponibles() async {
    final response = await _client.get('/delivery/available');
    return _lista(response.data);
  }

  /// 204 sin cuerpo: solo importa que la API acepte la asignación.
  Future<void> aceptar(String pedidoId) =>
      _client.post('/delivery/$pedidoId/accept');

  /// El backend devuelve un array aunque el repartidor solo tenga una entrega
  /// en curso; se conserva la lista y la respuesta activa vive en el repositorio.
  Future<List<PedidoEntregaDto>> listarActivos() async {
    final response = await _client.get('/delivery/active');
    return _lista(response.data);
  }

  Future<void> completar(String pedidoId) =>
      _client.post('/delivery/$pedidoId/complete');

  /// `GET /delivery/history` responde el array plano: la API no pagina aunque
  /// `04 §11.5` documente `data`/`meta` con `page` y `limit`.
  Future<List<PedidoEntregaDto>> listarHistorial() async {
    final response = await _client.get('/delivery/history');
    return _lista(response.data);
  }

  /// `GET` no existe para la disponibilidad: el estado se conoce al cambiarlo y,
  /// tras reiniciar, la primera llamada a `GET /delivery/available` ya implica
  /// que el backend lo considera disponible. La pantalla lo pide al abrir.
  Future<Disponibilidad> disponibilidad() async {
    final response = await _client.get('/delivery/availability');
    return _disponibilidad(response.data);
  }

  /// El endpoint devuelve el estado resultante, no un 204: así la app no tiene
  /// que suponer si el servidor aceptó el cambio o lo rechazó.
  Future<Disponibilidad> cambiarDisponibilidad(
    DeliveryPersonStatus estado,
  ) async {
    final response = await _client.put(
      '/delivery/availability',
      data: {'estado': estado.api},
    );
    return _disponibilidad(response.data);
  }

  static Disponibilidad _disponibilidad(Object? data) {
    final json = (data as Map?)?.cast<String, dynamic>() ?? const {};
    return Disponibilidad(
      estado: DeliveryPersonStatus.fromApi(json['estado']),
      tieneEntregaActiva: json['tieneEntregaActiva'] == true,
    );
  }

  Future<EstadisticasRepartidorDto> estadisticas() async {
    final response = await _client.get('/delivery/stats');
    return EstadisticasRepartidorDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  static List<PedidoEntregaDto> _lista(Object? data) {
    final items = data as List<dynamic>? ?? const [];
    return items
        .cast<Map<String, dynamic>>()
        .map(PedidoEntregaDto.fromJson)
        .toList(growable: false);
  }
}
