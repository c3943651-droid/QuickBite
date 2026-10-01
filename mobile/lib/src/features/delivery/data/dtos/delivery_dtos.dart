import 'package:json_annotation/json_annotation.dart';

part 'delivery_dtos.g.dart';

/// Réplica de `OrderResponse` (`GET /delivery/available`, `/active`,
/// `/history`). El `id` va antes de la acción en las rutas de accept y
/// complete, a diferencia de `04 §11.2`, y esas dos responden 204 sin cuerpo.
@JsonSerializable()
class PedidoEntregaDto {
  const PedidoEntregaDto({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    this.creadoEn,
    this.latitud,
    this.longitud,
  });

  factory PedidoEntregaDto.fromJson(Map<String, dynamic> json) =>
      _$PedidoEntregaDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PedidoEntregaDtoToJson(this);

  final String id;
  final String numeroPedido;
  final String estado;
  final double total;
  final DateTime? creadoEn;
  final double? latitud;
  final double? longitud;
}

/// Réplica de `DeliveryPersonStatsDto` (`GET /delivery/stats`).
@JsonSerializable()
class EstadisticasRepartidorDto {
  const EstadisticasRepartidorDto({
    required this.entregasTotales,
    required this.entregasDelMes,
    required this.tiempoPromedioEntregaMinutos,
    required this.pedidosAsignadosActivos,
    required this.cancelaciones,
  });

  factory EstadisticasRepartidorDto.fromJson(Map<String, dynamic> json) =>
      _$EstadisticasRepartidorDtoFromJson(json);
  Map<String, dynamic> toJson() => _$EstadisticasRepartidorDtoToJson(this);

  final int entregasTotales;
  final int entregasDelMes;
  final double tiempoPromedioEntregaMinutos;

  /// El backend lo llama `pedidosAsignadosActivos`; la pantalla lo presenta
  /// como "pedidos asignados".
  final int pedidosAsignadosActivos;
  final int cancelaciones;
}
