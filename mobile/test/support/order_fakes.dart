import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_repository.dart';

import 'cart_fakes.dart';

/// Pedidos en memoria para probar el checkout sin HTTP.
///
/// Reproduce lo que hace `OrderService.CreateAsync`: toma el carrito activo,
/// crea el pedido y lo deja vacío. Por eso recibe el fake del carrito; sin
/// esa parte la app vería un carrito con los mismos items después de pagar.
class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({this.cart});

  /// Si se asigna, `createOrder` lanza este error (p. ej. stock insuficiente).
  Object? error;

  final FakeCartRepository? cart;

  final List<
    ({
      String? direccionId,
      String direccionSnapshot,
      MetodoPago metodoPago,
      String? notasEntrega,
    })
  >
  creados = [];

  @override
  Future<Order> createOrder({
    String? direccionId,
    required String direccionSnapshot,
    required MetodoPago metodoPago,
    String? notasEntrega,
  }) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    creados.add((
      direccionId: direccionId,
      direccionSnapshot: direccionSnapshot,
      metodoPago: metodoPago,
      notasEntrega: notasEntrega,
    ));
    await cart?.clear();
    return const Order(
      id: 'o1',
      numeroPedido: 'QB-20260927-AB12CD',
      estado: 'Pendiente',
      total: 171,
      direccionEntrega: 'Av. Reforma 222, Int 3, Casa, CDMX',
      items: [OrderItem(nombre: 'Tacos al pastor', cantidad: 2)],
    );
  }

  @override
  Future<Order> getOrder(String id) => createOrder(
    direccionSnapshot: '',
    metodoPago: MetodoPago.efectivo,
  );
}
