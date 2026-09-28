import '../../../core/network/dio_client.dart';
import 'dtos/cart_dtos.dart';

/// Los cinco verbos del carrito (04 §6). El cuerpo de `POST /cart/items` usa
/// `opcionesIds` y `PUT /cart/items/{id}` solo admite cantidad y
/// observaciones, tal como los define el backend.
class CartRemoteDataSource {
  const CartRemoteDataSource(this._client);

  final ApiClient _client;

  Future<CartDto> getCart() async {
    final response = await _client.get('/cart');
    return CartDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CartDto> addItem(AddCartItemRequestDto request) async {
    final response = await _client.post('/cart/items', data: request.toJson());
    return CartDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CartDto> updateItem(
    String itemId,
    UpdateCartItemRequestDto request,
  ) async {
    final response = await _client.put(
      '/cart/items/$itemId',
      data: request.toJson(),
    );
    return CartDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeItem(String itemId) async {
    await _client.delete('/cart/items/$itemId');
  }

  Future<void> clear() async {
    await _client.delete('/cart');
  }
}
