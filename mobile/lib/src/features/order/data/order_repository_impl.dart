import '../domain/order_entities.dart';
import '../domain/order_repository.dart';
import 'dtos/order_dtos.dart';
import 'order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<Order> createOrder({
    String? direccionId,
    required String direccionSnapshot,
    required MetodoPago metodoPago,
    String? notasEntrega,
  }) async {
    final dto = await _remote.createOrder(
      CreateOrderRequestDto(
        direccionId: _clean(direccionId),
        direccionSnapshot: _snapshot(direccionSnapshot, notasEntrega),
        metodoPago: metodoPago.api,
      ),
    );
    return _toOrder(dto, direccionSnapshot: direccionSnapshot);
  }

  @override
  Future<Order> getOrder(String id) async {
    final dto = await _remote.getOrder(id);
    return _toOrder(
      OrderDto(
        id: dto.id,
        numeroPedido: dto.numeroPedido,
        estado: dto.estado,
        total: dto.total,
      ),
      direccionSnapshot: '',
      subtotal: dto.subtotal,
      costoEnvio: dto.costoEnvio,
      items: dto.items
          .map((n) => OrderItem(nombre: n, cantidad: 1))
          .toList(growable: false),
    );
  }

  @override
  Future<List<Order>> listOrders() async {
    final dtos = await _remote.listOrders();
    return dtos
        .map((dto) => _toOrder(dto, direccionSnapshot: ''))
        .toList(growable: false);
  }

  @override
  Future<EstadoPedidoActualizado> getStatus(String id) async {
    final dto = await _remote.getStatus(id);
    return EstadoPedidoActualizado(
      id: dto.id,
      estado: EstadoPedido.fromApi(dto.estado),
      actualizadoEn: dto.actualizadoEn.toUtc(),
    );
  }

  @override
  Future<void> cancelOrder(String id, {String? motivo}) async {
    await _remote.cancelOrder(id, motivo: motivo?.trim() ?? '');
  }

  /// `CreateOrderRequest` no tiene campo de notas, así que el texto se
  /// adjunta al snapshot de entrega: es el único lugar donde la API lo
  /// conserva y donde el repartidor lo lee.
  static String _snapshot(String direccion, String? notas) {
    final nota = _clean(notas);
    if (nota == null) return direccion;
    return '$direccion — Nota: $nota';
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static Order _toOrder(
    OrderDto dto, {
    required String direccionSnapshot,
    double? subtotal,
    double? costoEnvio,
    List<OrderItem> items = const [],
  }) {
    return Order(
      id: dto.id,
      numeroPedido: dto.numeroPedido,
      estado: dto.estado,
      total: dto.total,
      direccionEntrega: direccionSnapshot,
      items: items,
      subtotal: subtotal,
      costoEnvio: costoEnvio,
      creadoEn: dto.creadoEn,
    );
  }
}
