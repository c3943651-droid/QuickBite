import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/cart_remote_data_source.dart';
import '../data/cart_repository_impl.dart';
import '../domain/cart_entities.dart';
import '../domain/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(CartRemoteDataSource(ref.watch(apiClientProvider)));
});

/// El carrito vive en el servidor (04 §6), así que el provider es la caché de
/// la última respuesta conocida: sobrevive a la navegación entre pantallas y se
/// invalida con `refresh` al volver a la pestaña.
final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(
  CartNotifier.new,
);

/// Número de items para la insignia del carrito en la barra de navegación.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).value?.cantidadItems ?? 0;
});

class CartNotifier extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() => ref.watch(cartRepositoryProvider).getCart();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(cartRepositoryProvider).getCart(),
    );
  }

  /// 04 §6.2 — la API fusiona el item si el producto ya está con las mismas
  /// opciones, así que el estado se reemplaza con el carrito que devuelve.
  Future<void> addItem({
    required String productoId,
    required int cantidad,
    String? observaciones,
    List<String> opcionIds = const [],
  }) async {
    final carrito = await ref
        .read(cartRepositoryProvider)
        .addItem(
          productoId: productoId,
          cantidad: cantidad,
          observaciones: observaciones,
          opcionIds: opcionIds,
        );
    state = AsyncData(carrito);
  }

  /// Bajar a 0 borra el item: 04 §6.3 lo describe como eliminar y el backend
  /// no acepta cantidad 0. Una cantidad negativa se ignora —el selector de
  /// cantidad nunca la produce— para no borrar un item por un error de la UI.
  Future<void> setQuantity(String itemId, int cantidad) async {
    if (cantidad == 0) {
      await removeItem(itemId);
      return;
    }
    if (cantidad < 0) {
      return;
    }
    final actual = state.value?.itemById(itemId);
    if (actual == null || actual.cantidad == cantidad) {
      return;
    }
    final carrito = await ref
        .read(cartRepositoryProvider)
        .updateItem(
          itemId: itemId,
          cantidad: cantidad,
          observaciones: actual.observaciones,
        );
    state = AsyncData(carrito);
  }

  /// 04 §6.3 — `PUT` solo admite cantidad y observaciones, así que cambiar las
  /// opciones es quitar la línea y volver a agregarla. Si el re-agrego falla el
  /// item ya no existe en el servidor: se relee el carrito y el error sube para
  /// que la UI avise en vez de mostrar una línea fantasma.
  Future<void> replaceItemOptions(
    CartItem item, {
    required List<String> opcionIds,
  }) async {
    final repo = ref.read(cartRepositoryProvider);
    await repo.removeItem(item.id);
    try {
      final carrito = await repo.addItem(
        productoId: item.productoId,
        cantidad: item.cantidad,
        observaciones: item.observaciones,
        opcionIds: opcionIds,
      );
      state = AsyncData(carrito);
    } on Exception {
      state = AsyncData(await repo.getCart());
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    final repo = ref.read(cartRepositoryProvider);
    await repo.removeItem(itemId);
    // El DELETE no devuelve cuerpo (204): el estado se recalcula desde la
    // respuesta del servidor para no inventar nada.
    state = AsyncData(await repo.getCart());
  }

  Future<void> clear() async {
    if (state.value?.isEmpty ?? true) {
      return;
    }
    final repo = ref.read(cartRepositoryProvider);
    await repo.clear();
    state = AsyncData(await repo.getCart());
  }
}
