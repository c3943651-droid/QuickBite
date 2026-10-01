// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrderRequestDto _$CreateOrderRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateOrderRequestDto(
  direccionId: json['direccionId'] as String?,
  direccionSnapshot: json['direccionSnapshot'] as String,
  metodoPago: json['metodoPago'] as String,
);

Map<String, dynamic> _$CreateOrderRequestDtoToJson(
  CreateOrderRequestDto instance,
) => <String, dynamic>{
  'direccionId': ?instance.direccionId,
  'direccionSnapshot': instance.direccionSnapshot,
  'metodoPago': instance.metodoPago,
};

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
  id: json['id'] as String,
  numeroPedido: json['numeroPedido'] as String,
  estado: json['estado'] as String,
  total: (json['total'] as num).toDouble(),
  creadoEn: json['creadoEn'] == null
      ? null
      : DateTime.parse(json['creadoEn'] as String),
  latitud: (json['latitud'] as num?)?.toDouble(),
  longitud: (json['longitud'] as num?)?.toDouble(),
);

Map<String, dynamic> _$OrderDtoToJson(OrderDto instance) => <String, dynamic>{
  'id': instance.id,
  'numeroPedido': instance.numeroPedido,
  'estado': instance.estado,
  'total': instance.total,
  'creadoEn': instance.creadoEn?.toIso8601String(),
  'latitud': instance.latitud,
  'longitud': instance.longitud,
};

OrderDetailDto _$OrderDetailDtoFromJson(Map<String, dynamic> json) =>
    OrderDetailDto(
      id: json['id'] as String,
      numeroPedido: json['numeroPedido'] as String,
      estado: json['estado'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      costoEnvio: (json['costoEnvio'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );

OrderStatusDto _$OrderStatusDtoFromJson(Map<String, dynamic> json) =>
    OrderStatusDto(
      id: json['id'] as String,
      estado: json['estado'] as String,
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );

CancelOrderRequestDto _$CancelOrderRequestDtoFromJson(
  Map<String, dynamic> json,
) => CancelOrderRequestDto(motivo: json['motivo'] as String);

Map<String, dynamic> _$CancelOrderRequestDtoToJson(
  CancelOrderRequestDto instance,
) => <String, dynamic>{'motivo': instance.motivo};
