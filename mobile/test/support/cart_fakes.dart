import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_entities.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_repository.dart';

/// Carrito en memoria para probar providers y pantallas sin HTTP.
///
/// Reproduce lo que hace el backend: `addItem` fusiona por producto y
///combination de opciones, `updateItem` solo toca cantidad y observaciones,
/// `removeItem` quita la línea y las operaciones `DELETE` dejan el carrito
/// listo para releer.
class FakeCartRepository implements CartRepository {
  FakeCartRepository({this.failOnAdd = false});

  bool failOnAdd;

  /// Si está activo, `getCart` lanza este error (para probar estados de fallo).
  Object? error;

  /// Si está activo, `clear` lanza este error.
  Object? clearError;

  Cart current = const Cart(id: 'cart-1', items: [], total: 0);
  int getCalls = 0;
  int clearCalls = 0;
  int removeCalls = 0;
  final List<String> removed = [];
  final List<({String itemId, int cantidad, String? observaciones})> updates =
      [];
  final List<
    ({String productoId, int cantidad, String? observaciones, List<String> ids})
  >
  adds = [];

  @override
  Future<Cart> getCart() async {
    getCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return current;
  }

  @override
  Future<Cart> addItem({
    required String productoId,
    required int cantidad,
    String? observaciones,
    List<String> opcionIds = const [],
  }) async {
    adds.add((
      productoId: productoId,
      cantidad: cantidad,
      observaciones: observaciones,
      ids: opcionIds,
    ));
    if (failOnAdd) {
      throw const ValidationException('Stock insuficiente');
    }
    final items = [...current.items];
    final index = items.indexWhere(
      (i) =>
          i.productoId == productoId &&
          _mismismasOpciones(i.opciones, opcionIds),
    );
    if (index == -1) {
      items.add(
        CartItem(
          id: 'i${items.length + 1}',
          productoId: productoId,
          nombre: 'Tacos al pastor',
          precio: 85.50,
          cantidad: cantidad,
          opciones: opcionIds,
          observaciones: observaciones,
        ),
      );
    } else {
      final item = items[index];
      items[index] = CartItem(
        id: item.id,
        productoId: item.productoId,
        nombre: item.nombre,
        precio: item.precio,
        cantidad: item.cantidad + cantidad,
        opciones: item.opciones,
        observaciones: item.observaciones,
        imagenUrl: item.imagenUrl,
      );
    }
    current = Cart(id: 'cart-1', items: items, total: _total(items));
    return current;
  }

  @override
  Future<Cart> updateItem({
    required String itemId,
    required int cantidad,
    String? observaciones,
  }) async {
    updates.add((
      itemId: itemId,
      cantidad: cantidad,
      observaciones: observaciones,
    ));
    final items = [
      for (final item in current.items)
        if (item.id == itemId)
          CartItem(
            id: item.id,
            productoId: item.productoId,
            nombre: item.nombre,
            precio: item.precio,
            cantidad: cantidad,
            opciones: item.opciones,
            observaciones: observaciones,
            imagenUrl: item.imagenUrl,
          )
        else
          item,
    ];
    current = Cart(id: 'cart-1', items: items, total: _total(items));
    return current;
  }

  @override
  Future<void> removeItem(String itemId) async {
    removeCalls++;
    removed.add(itemId);
    current = Cart(
      id: 'cart-1',
      items: current.items.where((i) => i.id != itemId).toList(),
      total: 0,
    );
  }

  @override
  Future<void> clear() async {
    final failure = clearError;
    if (failure != null) {
      throw failure;
    }
    clearCalls++;
    current = const Cart(id: 'cart-1', items: [], total: 0);
  }

  static double _total(List<CartItem> items) =>
      items.fold(0, (sum, item) => sum + item.subtotal);

  static bool _mismismasOpciones(List<String> actuales, List<String> nuevas) {
    if (actuales.length != nuevas.length) {
      return false;
    }
    final a = [...actuales]..sort();
    final b = [...nuevas]..sort();
    return a.join('|') == b.join('|');
  }
}
