// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sesion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SesionDto _$SesionDtoFromJson(Map<String, dynamic> json) => SesionDto(
  id: json['id'] as String,
  creadoEn: DateTime.parse(json['creado_en'] as String),
  expiraEn: DateTime.parse(json['expira_en'] as String),
  esActual: json['es_actual'] as bool,
  ipOrigen: json['ip_origen'] as String?,
  userAgent: json['user_agent'] as String?,
);

Map<String, dynamic> _$SesionDtoToJson(SesionDto instance) => <String, dynamic>{
  'id': instance.id,
  'ip_origen': instance.ipOrigen,
  'user_agent': instance.userAgent,
  'creado_en': instance.creadoEn.toIso8601String(),
  'expira_en': instance.expiraEn.toIso8601String(),
  'es_actual': instance.esActual,
};

ChangePasswordRequestDto _$ChangePasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequestDto(
  currentPassword: json['currentPassword'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestDtoToJson(
  ChangePasswordRequestDto instance,
) => <String, dynamic>{
  'currentPassword': instance.currentPassword,
  'newPassword': instance.newPassword,
};
