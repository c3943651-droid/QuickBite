import 'cart_entities.dart';

abstract interface class CartRepository {
  /// 04 §6.1 — si el cliente no tiene carrito, la API devuelve uno vacío.
  Future<Cart> getCart();

  /// 04 §6.2 — si el producto ya está con las mismas opciones, la API suma la
  /// cantidad. Devuelve el carrito resultante, no solo el item.
  Future<Cart> addItem({
    required String productoId,
    required int cantidad,
    String? observaciones,
    List<String> opcionIds = const [],
  });

  /// 04 §6.3
  Future<Cart> updateItem({
    required String itemId,
    required int cantidad,
    String? observaciones,
  });

  /// 04 §6.4
  Future<void> removeItem(String itemId);

  /// 04 §6.5
  Future<void> clear();
}
