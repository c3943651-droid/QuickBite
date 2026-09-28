// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemDto _$CartItemDtoFromJson(Map<String, dynamic> json) => CartItemDto(
  id: json['id'] as String,
  productoId: json['productoId'] as String,
  nombre: json['nombre'] as String,
  precio: (json['precio'] as num).toDouble(),
  cantidad: (json['cantidad'] as num).toInt(),
  opciones:
      (json['opciones'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  subtotal: (json['subtotal'] as num?)?.toDouble(),
  observaciones: json['observaciones'] as String?,
  imagenUrl: json['imagenUrl'] as String?,
);

Map<String, dynamic> _$CartItemDtoToJson(CartItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productoId': instance.productoId,
      'nombre': instance.nombre,
      'precio': instance.precio,
      'cantidad': instance.cantidad,
      'opciones': instance.opciones,
      'subtotal': instance.subtotal,
      'observaciones': instance.observaciones,
      'imagenUrl': instance.imagenUrl,
    };

CartDto _$CartDtoFromJson(Map<String, dynamic> json) => CartDto(
  id: json['id'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  subtotal: (json['subtotal'] as num?)?.toDouble(),
  costoEnvio: (json['costoEnvio'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CartDtoToJson(CartDto instance) => <String, dynamic>{
  'id': instance.id,
  'items': instance.items,
  'total': instance.total,
  'subtotal': instance.subtotal,
  'costoEnvio': instance.costoEnvio,
};

AddCartItemRequestDto _$AddCartItemRequestDtoFromJson(
  Map<String, dynamic> json,
) => AddCartItemRequestDto(
  productoId: json['productoId'] as String,
  cantidad: (json['cantidad'] as num).toInt(),
  observaciones: json['observaciones'] as String?,
  opcionesIds: (json['opcionesIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AddCartItemRequestDtoToJson(
  AddCartItemRequestDto instance,
) => <String, dynamic>{
  'productoId': instance.productoId,
  'cantidad': instance.cantidad,
  'observaciones': ?instance.observaciones,
  'opcionesIds': ?instance.opcionesIds,
};

UpdateCartItemRequestDto _$UpdateCartItemRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateCartItemRequestDto(
  cantidad: (json['cantidad'] as num).toInt(),
  observaciones: json['observaciones'] as String?,
);

Map<String, dynamic> _$UpdateCartItemRequestDtoToJson(
  UpdateCartItemRequestDto instance,
) => <String, dynamic>{
  'cantidad': instance.cantidad,
  'observaciones': ?instance.observaciones,
};
