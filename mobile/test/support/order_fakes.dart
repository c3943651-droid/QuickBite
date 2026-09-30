import 'dart:async';

import 'package:quickbite_mobile/src/core/error/app_exception.dart';
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

  /// Pedidos que devuelve `listOrders` y `getOrder`.
  List<Order> pedidos = [];

  /// Si se asigna, `listOrders` lanza este error.
  Object? listError;

  /// Si se asigna, `getStatus` lanza este error.
  Object? statusError;

  /// Cuántas veces se consultó el estado: el polling se cuenta aquí.
  int consultasStatus = 0;

  /// Si se asigna, `getStatus` devuelve este estado en lugar del del pedido.
  EstadoPedido? estadoForzado;

  /// Si está asignado, `getStatus` espera a que se complete antes de responder;
  /// sirve para observar la consulta en vuelo en los tests de widget.
  Completer<void>? statusGate;

  /// Si se asigna, `cancelOrder` lanza este error.
  Object? cancelError;

  /// Motivos con los que se intentó cancelar.
  final List<({String id, String motivo})> cancelaciones = [];

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
  Future<Order> getOrder(String id) async {
    final found = pedidos.where((o) => o.id == id);
    if (found.isEmpty) {
      throw NotFoundException('Ese pedido ya no existe.');
    }
    return found.first;
  }

  @override
  Future<List<Order>> listOrders() async {
    final failure = listError;
    if (failure != null) {
      throw failure;
    }
    return List.unmodifiable(pedidos);
  }

  @override
  Future<EstadoPedidoActualizado> getStatus(String id) async {
    consultasStatus++;
    final failure = statusError;
    if (failure != null) {
      throw failure;
    }
    await statusGate?.future;
    final forzado = estadoForzado;
    final pedido = await getOrder(id);
    return EstadoPedidoActualizado(
      id: id,
      estado: forzado ?? pedido.estadoPedido,
      actualizadoEn: DateTime.utc(2026, 9, 27, 15, 10),
    );
  }

  @override
  Future<void> cancelOrder(String id, {String? motivo}) async {
    final failure = cancelError;
    if (failure != null) {
      throw failure;
    }
    cancelaciones.add((id: id, motivo: motivo ?? ''));
    pedidos = pedidos
        .map(
          (o) => o.id == id
              ? Order(
                  id: o.id,
                  numeroPedido: o.numeroPedido,
                  estado: EstadoPedido.cancelado.api,
                  total: o.total,
                  direccionEntrega: o.direccionEntrega,
                  items: o.items,
                  subtotal: o.subtotal,
                  costoEnvio: o.costoEnvio,
                  creadoEn: o.creadoEn,
                )
              : o,
        )
        .toList(growable: false);
  }
}
