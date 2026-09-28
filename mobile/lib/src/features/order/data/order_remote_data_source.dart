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
}
