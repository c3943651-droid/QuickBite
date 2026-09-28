import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

import 'checkout_providers.dart';

/// Historial de pedidos del cliente (07.1 SCR-ORDER-03).
///
/// `GET /orders` no acepta filtros: el backend devuelve todo y la app filtra en
/// cliente (decisión 1 de 07.3). `retry` se anula a propósito para que un fallo
/// muestre el error con su botón de reintento en vez de un skeleton eterno.
final ordersProvider = FutureProvider.autoDispose<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).listOrders(),
  retry: (retryCount, error) => null,
);

final orderFilterProvider = NotifierProvider<OrderFilterNotifier, FiltroPedido>(
  OrderFilterNotifier.new,
);

class OrderFilterNotifier extends Notifier<FiltroPedido> {
  @override
  FiltroPedido build() => FiltroPedido.todos;

  void seleccionar(FiltroPedido filtro) => state = filtro;
}

/// Los pedidos del historial que pasan el chip activo.
final ordersFiltradosProvider = Provider<List<Order>>((ref) {
  final pedidos = ref.watch(ordersProvider).value ?? const <Order>[];
  final filtro = ref.watch(orderFilterProvider);
  return pedidos
      .where((pedido) => filtro.incluye(pedido.estadoPedido))
      .toList(growable: false);
});
