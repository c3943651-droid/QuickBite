// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PedidoEntregaDto _$PedidoEntregaDtoFromJson(Map<String, dynamic> json) =>
    PedidoEntregaDto(
      id: json['id'] as String,
      numeroPedido: json['numeroPedido'] as String,
      estado: json['estado'] as String,
      total: (json['total'] as num).toDouble(),
      creadoEn: json['creadoEn'] == null
          ? null
          : DateTime.parse(json['creadoEn'] as String),
    );

Map<String, dynamic> _$PedidoEntregaDtoToJson(PedidoEntregaDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'numeroPedido': instance.numeroPedido,
      'estado': instance.estado,
      'total': instance.total,
      'creadoEn': instance.creadoEn?.toIso8601String(),
    };

EstadisticasRepartidorDto _$EstadisticasRepartidorDtoFromJson(
  Map<String, dynamic> json,
) => EstadisticasRepartidorDto(
  entregasTotales: (json['entregasTotales'] as num).toInt(),
  entregasDelMes: (json['entregasDelMes'] as num).toInt(),
  tiempoPromedioEntregaMinutos: (json['tiempoPromedioEntregaMinutos'] as num)
      .toDouble(),
  pedidosAsignadosActivos: (json['pedidosAsignadosActivos'] as num).toInt(),
  cancelaciones: (json['cancelaciones'] as num).toInt(),
);

Map<String, dynamic> _$EstadisticasRepartidorDtoToJson(
  EstadisticasRepartidorDto instance,
) => <String, dynamic>{
  'entregasTotales': instance.entregasTotales,
  'entregasDelMes': instance.entregasDelMes,
  'tiempoPromedioEntregaMinutos': instance.tiempoPromedioEntregaMinutos,
  'pedidosAsignadosActivos': instance.pedidosAsignadosActivos,
  'cancelaciones': instance.cancelaciones,
};
