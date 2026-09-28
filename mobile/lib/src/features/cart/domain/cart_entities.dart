import 'package:equatable/equatable.dart';

/// Item del carrito tal como lo modela la API (04 §6.1). `opciones` llegan como
/// nombres ya resueltos y `subtotal` puede no venir, por lo que el precio de
/// la entidad cubre ese hueco.
class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.opciones = const [],
    this.observaciones,
    this.imagenUrl,
    this.subtotalApi,
  });

  final String id;
  final String productoId;
  final String nombre;
  final double precio;
  final int cantidad;
  final List<String> opciones;
  final String? observaciones;
  final String? imagenUrl;

  /// Lo que envía la API, que hoy puede no venir. Se guarda aparte para no
  /// perder la diferencia entre el dato del servidor y el valor de dominio.
  final double? subtotalApi;

  /// 04 §6.1 no garantiza `subtotal`: si falta se deriva del precio unitario.
  double get subtotal => subtotalApi ?? precio * cantidad;

  @override
  List<Object?> get props => [
    id,
    productoId,
    nombre,
    precio,
    cantidad,
    opciones,
    observaciones,
    imagenUrl,
    subtotalApi,
  ];
}

class Cart extends Equatable {
  const Cart({
    required this.id,
    required this.items,
    required this.total,
    this.subtotalApi,
    this.costoEnvioApi,
  });

  final String id;
  final List<CartItem> items;
  final double total;

  /// 04 §6.1 los documenta pero el backend aún no los emite; cuando lleguen,
  /// mandan sobre los valores derivados.
  final double? subtotalApi;
  final double? costoEnvioApi;

  bool get isEmpty => items.isEmpty;

  int get cantidadItems => items.length;

  /// El backend todavía no envía `subtotal` del carrito, así que se suma desde
  /// los items para que RF-03.4 siempre pueda mostrarlo.
  double get subtotal => subtotalApi ?? _sumaItems;

  /// RF-03.4 pide mostrar el envío. Hoy la API no lo expone y lo descuenta del
  /// total; cuando `costoEnvio` llegue, manda el valor del servidor.
  double get costoEnvio {
    final envio = costoEnvioApi;
    if (envio != null) {
      return envio;
    }
    final diferencia = total - _sumaItems;
    return diferencia > 0 ? diferencia : 0;
  }

  double get _sumaItems =>
      items.fold<double>(0, (suma, item) => suma + item.subtotal);

  CartItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [id, items, total, subtotalApi, costoEnvioApi];
}
