import 'package:json_annotation/json_annotation.dart';

part 'order_dtos.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateOrderRequestDto {
  const CreateOrderRequestDto({
    this.direccionId,
    required this.direccionSnapshot,
    required this.metodoPago,
  });

  factory CreateOrderRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderRequestDtoToJson(this);

  final String? direccionId;
  final String direccionSnapshot;
  final String metodoPago;
}

@JsonSerializable()
class OrderDto {
  const OrderDto({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    this.creadoEn,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);

  final String id;
  final String numeroPedido;
  final String estado;
  final double total;
  final DateTime? creadoEn;
}

/// `GET /orders/{id}` devuelve los items como una lista de nombres sueltos y
/// solo se lee, así que no necesita serializar hacia atrás.
@JsonSerializable(createToJson: false)
class OrderDetailDto {
  const OrderDetailDto({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    this.items = const [],
  });

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailDtoFromJson(json);

  final String id;
  final String numeroPedido;
  final String estado;
  final double subtotal;
  final double costoEnvio;
  final double total;
  final List<String> items;
}

@JsonSerializable(createToJson: false)
class OrderStatusDto {
  const OrderStatusDto({
    required this.id,
    required this.estado,
    required this.actualizadoEn,
  });

  factory OrderStatusDto.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusDtoFromJson(json);

  final String id;
  final String estado;
  final DateTime actualizadoEn;
}

@JsonSerializable()
class CancelOrderRequestDto {
  const CancelOrderRequestDto({required this.motivo});

  factory CancelOrderRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CancelOrderRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CancelOrderRequestDtoToJson(this);

  final String motivo;
}
