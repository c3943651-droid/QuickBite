import 'package:json_annotation/json_annotation.dart';

import '../../domain/address_entities.dart';

part 'address_dtos.g.dart';

@JsonSerializable()
class AddressDto {
  const AddressDto({
    required this.id,
    required this.calle,
    required this.ciudad,
    this.alias,
    this.numero,
    this.referencia,
    this.latitud,
    this.longitud,
    this.esPredeterminada = false,
    this.creadoEn,
  });

  factory AddressDto.fromJson(Map<String, dynamic> json) =>
      _$AddressDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AddressDtoToJson(this);

  final String id;
  final String calle;
  final String ciudad;
  final String? alias;
  final String? numero;
  final String? referencia;
  final double? latitud;
  final double? longitud;

  @JsonKey(name: 'es_predeterminada')
  final bool esPredeterminada;

  @JsonKey(name: 'creado_en')
  final DateTime? creadoEn;

  Address toEntity() {
    return Address(
      id: id,
      calle: calle,
      ciudad: ciudad,
      alias: alias,
      numero: numero,
      referencia: referencia,
      latitud: latitud,
      longitud: longitud,
      esPredeterminada: esPredeterminada,
      creadoEn: creadoEn,
    );
  }
}

@JsonSerializable()
class AddressRequestDto {
  const AddressRequestDto({
    this.calle,
    this.ciudad,
    this.alias,
    this.numero,
    this.referencia,
    this.latitud,
    this.longitud,
    this.esPredeterminada,
  });

  factory AddressRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AddressRequestDtoFromJson(json);

  final String? calle;
  final String? ciudad;
  final String? alias;
  final String? numero;
  final String? referencia;
  final double? latitud;
  final double? longitud;

  @JsonKey(name: 'es_predeterminada')
  final bool? esPredeterminada;

  /// El contrato marca calle y ciudad como obligatorias al crear, pero el PUT
  /// las declara opcionales. Un `null` significa "sin cambios", así que la
  /// clave se omite del cuerpo en lugar de mandarse como vacía.
  Map<String, dynamic> toJson() =>
      _$AddressRequestDtoToJson(this)..removeWhere((_, value) => value == null);
}
