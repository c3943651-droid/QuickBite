// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressDto _$AddressDtoFromJson(Map<String, dynamic> json) => AddressDto(
  id: json['id'] as String,
  calle: json['calle'] as String,
  ciudad: json['ciudad'] as String,
  alias: json['alias'] as String?,
  numero: json['numero'] as String?,
  referencia: json['referencia'] as String?,
  latitud: (json['latitud'] as num?)?.toDouble(),
  longitud: (json['longitud'] as num?)?.toDouble(),
  esPredeterminada: json['es_predeterminada'] as bool? ?? false,
  creadoEn: json['creado_en'] == null
      ? null
      : DateTime.parse(json['creado_en'] as String),
);

Map<String, dynamic> _$AddressDtoToJson(AddressDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'calle': instance.calle,
      'ciudad': instance.ciudad,
      'alias': instance.alias,
      'numero': instance.numero,
      'referencia': instance.referencia,
      'latitud': instance.latitud,
      'longitud': instance.longitud,
      'es_predeterminada': instance.esPredeterminada,
      'creado_en': instance.creadoEn?.toIso8601String(),
    };

AddressRequestDto _$AddressRequestDtoFromJson(Map<String, dynamic> json) =>
    AddressRequestDto(
      calle: json['calle'] as String?,
      ciudad: json['ciudad'] as String?,
      alias: json['alias'] as String?,
      numero: json['numero'] as String?,
      referencia: json['referencia'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      esPredeterminada: json['es_predeterminada'] as bool?,
    );

Map<String, dynamic> _$AddressRequestDtoToJson(AddressRequestDto instance) =>
    <String, dynamic>{
      'calle': instance.calle,
      'ciudad': instance.ciudad,
      'alias': instance.alias,
      'numero': instance.numero,
      'referencia': instance.referencia,
      'latitud': instance.latitud,
      'longitud': instance.longitud,
      'es_predeterminada': instance.esPredeterminada,
    };
