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
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      costoEnvio: (json['costoEnvio'] as num?)?.toDouble(),
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      creadoEn: json['creadoEn'] == null
          ? null
          : DateTime.parse(json['creadoEn'] as String),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      cliente: json['cliente'] as String?,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
    );

Map<String, dynamic> _$PedidoEntregaDtoToJson(PedidoEntregaDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'numeroPedido': instance.numeroPedido,
      'estado': instance.estado,
      'total': instance.total,
      'subtotal': instance.subtotal,
      'costoEnvio': instance.costoEnvio,
      'items': instance.items,
      'creadoEn': instance.creadoEn?.toIso8601String(),
      'latitud': instance.latitud,
      'longitud': instance.longitud,
      'cliente': instance.cliente,
      'direccion': instance.direccion,
      'telefono': instance.telefono,
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
