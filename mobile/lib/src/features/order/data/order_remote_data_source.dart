import '../../../core/network/dio_client.dart';
import 'dtos/order_dtos.dart';

class OrderRemoteDataSource {
  const OrderRemoteDataSource(this._client);

  final ApiClient _client;

  Future<OrderDto> createOrder(CreateOrderRequestDto request) async {
    final response = await _client.post('/orders', data: request.toJson());
    return OrderDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderDetailDto> getOrder(String id) async {
    final response = await _client.get('/orders/$id');
    return OrderDetailDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OrderDto>> listOrders() async {
    final response = await _client.get('/orders');
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(OrderDto.fromJson)
        .toList(growable: false);
  }

  /// `GET /orders/{id}/status` es el endpoint que consume el polling: es más
  /// liviano que el detalle completo (04 §4.6).
  Future<OrderStatusDto> getStatus(String id) async {
    final response = await _client.get('/orders/$id/status');
    return OrderStatusDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// 204 sin cuerpo: solo importa que la API acepte la cancelación.
  Future<void> cancelOrder(String id, {required String motivo}) async {
    await _client.patch(
      '/orders/$id/cancel',
      data: CancelOrderRequestDto(motivo: motivo).toJson(),
    );
  }
}
