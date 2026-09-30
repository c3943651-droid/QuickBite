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

  /// Historial completo del cliente; el filtrado por estado es en cliente.
  Future<List<Order>> listOrders();

  Future<EstadoPedidoActualizado> getStatus(String id);

  Future<void> cancelOrder(String id, {String? motivo});
}
