import 'package:equatable/equatable.dart';

/// Métodos de pago simulados (05#D-08). El backend solo acepta `efectivo` y
/// `tarjeta`: el enum `PaymentMethodType` y su validador no contemplan otros
/// valores, así que la app no puede ofrecer otros sin un cambio previo.
enum MetodoPago {
  efectivo('efectivo', 'Efectivo contra entrega'),
  tarjeta('tarjeta', 'Tarjeta (simulado)');

  const MetodoPago(this.api, this.etiqueta);

  /// Valor exacto que espera `POST /orders`.
  final String api;

  final String etiqueta;

  static MetodoPago fromApi(String value) => values.firstWhere(
    (metodo) => metodo.api == value.trim().toLowerCase(),
    orElse: () => MetodoPago.efectivo,
  );
}

class OrderItem extends Equatable {
  const OrderItem({required this.nombre, required this.cantidad});

  final String nombre;
  final int cantidad;

  @override
  List<Object?> get props => [nombre, cantidad];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    required this.direccionEntrega,
    required this.items,
    this.subtotal,
    this.costoEnvio,
    this.creadoEn,
  });

  /// `POST /orders` todavía no devuelve un tiempo estimado (la clave
  /// `tiempo_entrega_estimado` vive en la configuración del panel admin sin
  /// exponerla por API), así que la app muestra su valor por defecto.
  static const int tiempoEntregaEstimadoPorDefecto = 40;

  final String id;
  final String numeroPedido;
  final String estado;
  final double total;
  final String direccionEntrega;
  final List<OrderItem> items;
  final double? subtotal;
  final double? costoEnvio;
  final DateTime? creadoEn;

  int get tiempoEntregaEstimado => tiempoEntregaEstimadoPorDefecto;

  int get cantidadItems =>
      items.fold(0, (total, item) => total + item.cantidad);

  @override
  List<Object?> get props => [id, numeroPedido, estado, total, direccionEntrega];
}
