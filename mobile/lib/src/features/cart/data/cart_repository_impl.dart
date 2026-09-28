import '../domain/cart_entities.dart';
import '../domain/cart_repository.dart';
import 'cart_remote_data_source.dart';
import 'dtos/cart_dtos.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._remote);

  final CartRemoteDataSource _remote;

  @override
  Future<Cart> getCart() async => _toCart(await _remote.getCart());

  @override
  Future<Cart> addItem({
    required String productoId,
    required int cantidad,
    String? observaciones,
    List<String> opcionIds = const [],
  }) async {
    final notas = _clean(observaciones);
    final opciones = opcionIds.isEmpty ? null : opcionIds;
    final dto = await _remote.addItem(
      AddCartItemRequestDto(
        productoId: productoId,
        cantidad: cantidad,
        observaciones: notas,
        opcionesIds: opciones,
      ),
    );
    return _toCart(dto);
  }

  @override
  Future<Cart> updateItem({
    required String itemId,
    required int cantidad,
    String? observaciones,
  }) async {
    final dto = await _remote.updateItem(
      itemId,
      UpdateCartItemRequestDto(
        cantidad: cantidad,
        observaciones: _clean(observaciones),
      ),
    );
    return _toCart(dto);
  }

  @override
  Future<void> removeItem(String itemId) => _remote.removeItem(itemId);

  @override
  Future<void> clear() => _remote.clear();

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static Cart _toCart(CartDto dto) {
    return Cart(
      id: dto.id,
      items: dto.items.map(_toItem).toList(growable: false),
      total: dto.total,
      subtotalApi: dto.subtotal,
      costoEnvioApi: dto.costoEnvio,
    );
  }

  static CartItem _toItem(CartItemDto dto) {
    return CartItem(
      id: dto.id,
      productoId: dto.productoId,
      nombre: dto.nombre,
      precio: dto.precio,
      cantidad: dto.cantidad,
      opciones: dto.opciones,
      observaciones: dto.observaciones,
      imagenUrl: dto.imagenUrl,
      subtotalApi: dto.subtotal,
    );
  }
}
