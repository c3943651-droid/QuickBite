import 'package:equatable/equatable.dart';

import '../../order/domain/order_entities.dart';

/// Un pedido visto desde el repartidor (07.1 SCR-DEL-01 a SCR-DEL-05).
///
/// El backend responde los mismos `OrderResponse` que ve el cliente, así que
/// aquí solo existen los campos que la API manda de verdad. La dirección de
/// entrega y los productos que pide 07.1 para las pantallas del repartidor
/// todavía no los expone `GET /delivery/*`: ver `04 §11.1`. Cuando se añadan,
/// este entidad los recoge sin cambiar las pantallas.
class PedidoEntrega extends Equatable {
  const PedidoEntrega({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    this.creadoEn,
    this.latitud,
    this.longitud,
  });

  final String id;
  final String numeroPedido;
  final String estado;
  final double total;
  final DateTime? creadoEn;

  /// Coordenadas de destino copiadas de la dirección al crear el pedido
  /// (07.5 §3.3); null cuando la dirección no las tenía.
  final double? latitud;
  final double? longitud;

  EstadoPedido get estadoPedido => EstadoPedido.fromApi(estado);

  /// Un repartidor solo puede tomar pedidos que esperan y siguen libres.
  bool get sePuedeAceptar => estadoPedido == EstadoPedido.listo;

  /// Minutos desde que se creó el pedido, que es lo que la lista muestra como
  /// "tiempo desde que está listo". `null` si la API no envió la fecha.
  int? minutosDesdeCreacion(DateTime ahora) {
    final creado = creadoEn;
    if (creado == null) return null;
    final minutos = ahora.difference(creado.toUtc()).inMinutes;
    return minutos < 0 ? 0 : minutos;
  }

  @override
  List<Object?> get props => [
    id,
    numeroPedido,
    estado,
    total,
    creadoEn,
    latitud,
    longitud,
  ];
}
