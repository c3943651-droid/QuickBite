import 'order_entities.dart';

abstract interface class OrderRepository {
  /// Crea el pedido a partir del carrito activo del servidor, que queda
  /// vaciado por la propia API al confirmarse.
  Future<Order> createOrder({
    String? direccionId,
    required String direccionSnapshot,
    required MetodoPago metodoPago,
    String? notasEntrega,
  });

  Future<Order> getOrder(String id);
}
