import '../../../core/network/dio_client.dart';
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
