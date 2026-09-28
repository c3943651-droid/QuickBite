import 'package:json_annotation/json_annotation.dart';

part 'cart_dtos.g.dart';

@JsonSerializable()
class CartItemDto {
  const CartItemDto({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.opciones = const [],
    this.subtotal,
    this.observaciones,
    this.imagenUrl,
  });

  factory CartItemDto.fromJson(Map<String, dynamic> json) =>
      _$CartItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemDtoToJson(this);

  final String id;
  final String productoId;
  final String nombre;
  final double precio;
  final int cantidad;
  final List<String> opciones;
  final double? subtotal;
  final String? observaciones;
  final String? imagenUrl;
}

@JsonSerializable()
class CartDto {
  const CartDto({
    required this.id,
    required this.items,
    required this.total,
    this.subtotal,
    this.costoEnvio,
  });

  factory CartDto.fromJson(Map<String, dynamic> json) =>
      _$CartDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CartDtoToJson(this);

  final String id;
  final List<CartItemDto> items;
  final double total;

  /// 04 §6.1 los documenta, pero el backend actual solo devuelve `total`.
  final double? subtotal;
  final double? costoEnvio;
}

@JsonSerializable(includeIfNull: false)
class AddCartItemRequestDto {
  const AddCartItemRequestDto({
    required this.productoId,
    required this.cantidad,
    this.observaciones,
    this.opcionesIds,
  });

  factory AddCartItemRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AddCartItemRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AddCartItemRequestDtoToJson(this);

  final String productoId;
  final int cantidad;
  final String? observaciones;
  final List<String>? opcionesIds;
}

@JsonSerializable(includeIfNull: false)
class UpdateCartItemRequestDto {
  const UpdateCartItemRequestDto({required this.cantidad, this.observaciones});

  factory UpdateCartItemRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCartItemRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCartItemRequestDtoToJson(this);

  final int cantidad;
  final String? observaciones;
}
