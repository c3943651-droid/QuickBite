import 'package:equatable/equatable.dart';

import '../../order/domain/order_entities.dart';

/// Un pedido visto desde el repartidor (07.1 SCR-DEL-01 a SCR-DEL-05).
///
/// `GET /delivery/*` devuelve ya lo que el repartidor necesita para trabajar el
/// pedido (cliente, dirección, teléfono e ítems); son opcionales porque una
/// respuesta antigua o un pedido sin esos datos no debe dejar la pantalla en
/// blanco: la UI muestra solo lo que llega.
class PedidoEntrega extends Equatable {
  const PedidoEntrega({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    this.subtotal,
    this.costoEnvio,
    this.items = const [],
    this.creadoEn,
    this.latitud,
    this.longitud,
    this.cliente,
    this.direccion,
    this.telefono,
  });

  final String id;
  final String numeroPedido;
  final String estado;
  final double total;
  final double? subtotal;
  final double? costoEnvio;

  /// Productos pedidos, en el orden que los envió el backend.
  final List<String> items;
  final DateTime? creadoEn;

  /// A quién entregar y dónde.
  final String? cliente;
  final String? direccion;
  final String? telefono;

  /// `true` cuando el pedido trae dirección y coordenadas: sin eso la pantalla
  /// avisa en vez de abrir un mapa vacío.
  bool get tieneDestino => direccion?.trim().isNotEmpty ?? false;

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
    subtotal,
    costoEnvio,
    items,
    creadoEn,
    latitud,
    longitud,
    cliente,
    direccion,
    telefono,
  ];
}
