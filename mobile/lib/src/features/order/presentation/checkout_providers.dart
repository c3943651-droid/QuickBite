import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../address/domain/address_entities.dart';
import '../../address/presentation/address_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/order_remote_data_source.dart';
import '../data/order_repository_impl.dart';
import '../domain/order_entities.dart';
import '../domain/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(OrderRemoteDataSource(ref.watch(apiClientProvider)));
});

/// Estado del checkout (07.1 SCR-CART-02). Guarda la elección explícita del
/// usuario; la dirección predeterminada se deriva aparte para que recargar la
/// lista no borre lo ya elegido.
class CheckoutState extends Equatable {
  const CheckoutState({
    this.direccionId,
    this.metodoPago = MetodoPago.efectivo,
    this.notas = '',
    this.enviando = false,
    this.pedidoCreado,
    this.error,
  });

  final String? direccionId;
  final MetodoPago metodoPago;
  final String notas;
  final bool enviando;
  final Order? pedidoCreado;
  final String? error;

  CheckoutState copyWith({
    Object? direccionId = _unset,
    MetodoPago? metodoPago,
    String? notas,
    bool? enviando,
    Object? pedidoCreado = _unset,
    Object? error = _unset,
  }) {
    return CheckoutState(
      direccionId: identical(direccionId, _unset) ? this.direccionId : direccionId as String?,
      metodoPago: metodoPago ?? this.metodoPago,
      notas: notas ?? this.notas,
      enviando: enviando ?? this.enviando,
      pedidoCreado: identical(pedidoCreado, _unset)
          ? this.pedidoCreado
          : pedidoCreado as Order?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [
    direccionId,
    metodoPago,
    notas,
    enviando,
    pedidoCreado,
    error,
  ];
}

const _unset = Object();

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
);

/// Dirección efectiva: la elegida o, si el usuario no ha tocado nada, la
/// predeterminada. Si solo hay una guardada, esa se usa.
final checkoutDireccionProvider = Provider<Address?>((ref) {
  final elegida = ref.watch(checkoutProvider).direccionId;
  final direcciones = ref.watch(addressesProvider).value ?? const <Address>[];
  return elegida == null
      ? _direccionPorDefecto(direcciones)
      : _buscarPorId(direcciones, elegida);
});

/// El pedido recién creado alimenta la confirmación (07.1 SCR-CART-03 no llama
/// a la API), así que sobrevive a la navegación como estado del checkout.
final lastOrderProvider = Provider<Order?>((ref) {
  return ref.watch(checkoutProvider).pedidoCreado;
});

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void seleccionarDireccion(String direccionId) {
    state = state.copyWith(direccionId: direccionId, error: null);
  }

  void seleccionarMetodoPago(MetodoPago metodoPago) {
    state = state.copyWith(metodoPago: metodoPago, error: null);
  }

  void setNotas(String notas) {
    state = state.copyWith(notas: notas);
  }

  /// Crea el pedido desde el carrito activo. El servidor lo vacía al
  /// confirmarse, así que después se relee para que la insignia y el catálogo
  /// muestren el carrito vacío. Devuelve el pedido creado o `null` si no se
  /// pudo confirmar; el motivo queda en `error`.
  Future<Order?> confirmar() async {
    if (state.enviando) {
      return null;
    }
    final carrito = ref.read(cartProvider).value;
    if (carrito == null || carrito.isEmpty) {
      state = state.copyWith(error: 'Tu carrito está vacío.');
      return null;
    }
    final direccion = _direccionEfectiva(
      ref.read(addressesProvider).value ?? const <Address>[],
      state.direccionId,
    );
    if (direccion == null) {
      state = state.copyWith(error: 'Selecciona una dirección de entrega.');
      return null;
    }

    state = state.copyWith(enviando: true, error: null);
    try {
      final pedido = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            direccionId: direccion.id,
            direccionSnapshot: _snapshot(direccion),
            metodoPago: state.metodoPago,
            notasEntrega: state.notas,
          );
      await ref.read(cartProvider.notifier).refresh();
      state = state.copyWith(enviando: false, pedidoCreado: pedido);
      return pedido;
    } on AppException catch (error) {
      state = state.copyWith(enviando: false, error: error.userMessage);
      return null;
    }
  }

  /// `Order.DireccionEntregaSnapshot` es texto libre: se arma con lo que el
  /// cliente reconoce de la dirección para que el repartidor la ubique.
  static String _snapshot(Address direccion) {
    final partes = <String>[
      if (direccion.alias != null && direccion.alias!.isNotEmpty)
        direccion.alias!,
      [direccion.calle, direccion.numero]
          .where((valor) => valor != null && valor.isNotEmpty)
          .join(' '),
      if (direccion.ciudad.isNotEmpty) direccion.ciudad,
      if (direccion.referencia != null && direccion.referencia!.isNotEmpty)
        'Ref: ${direccion.referencia}',
    ];
    return partes.join(', ');
  }
}

/// La dirección que se usa si el usuario no ha elegido otra. Vive fuera del
/// notifier para que la pantalla y `confirmar` apliquen la misma regla sin
/// depender la una de la otra.
Address? _direccionEfectiva(List<Address> direcciones, String? elegidaId) {
  if (elegidaId == null) return _direccionPorDefecto(direcciones);
  return _buscarPorId(direcciones, elegidaId);
}

Address? _direccionPorDefecto(List<Address> direcciones) {
  if (direcciones.isEmpty) return null;
  return direcciones.firstWhere(
    (direccion) => direccion.esPredeterminada,
    orElse: () => direcciones.first,
  );
}

Address? _buscarPorId(List<Address> direcciones, String id) {
  for (final direccion in direcciones) {
    if (direccion.id == id) return direccion;
  }
  return null;
}
