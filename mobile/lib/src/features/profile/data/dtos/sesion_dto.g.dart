// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sesion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SesionDto _$SesionDtoFromJson(Map<String, dynamic> json) => SesionDto(
  id: _texto(json['id']),
  creadoEn: _fechaOpcional(json['creado_en']),
  expiraEn: _fechaOpcional(json['expira_en']),
  esActual: _booleano(json['es_actual']),
  ipOrigen: _textoOpcional(json['ip_origen']),
  userAgent: _textoOpcional(json['user_agent']),
);

Map<String, dynamic> _$SesionDtoToJson(SesionDto instance) => <String, dynamic>{
  'id': instance.id,
  'ip_origen': instance.ipOrigen,
  'user_agent': instance.userAgent,
  'creado_en': instance.creadoEn?.toIso8601String(),
  'expira_en': instance.expiraEn?.toIso8601String(),
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
