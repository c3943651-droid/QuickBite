// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: _texto(json['id']),
      nombre: _texto(json['nombre']),
      email: _texto(json['email']),
      rol: _texto(json['rol']),
      telefono: _textoOpcional(json['telefono']),
      creadoEn: _fechaOpcional(json['creado_en']),
      ultimoLogin: _fechaOpcional(json['ultimo_login']),
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'email': instance.email,
      'rol': instance.rol,
      'telefono': instance.telefono,
      'creado_en': instance.creadoEn?.toIso8601String(),
      'ultimo_login': instance.ultimoLogin?.toIso8601String(),
    };

UpdateProfileRequestDto _$UpdateProfileRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequestDto(
  nombre: json['nombre'] as String?,
  telefono: json['telefono'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestDtoToJson(
  UpdateProfileRequestDto instance,
) => <String, dynamic>{
  'nombre': instance.nombre,
  'telefono': instance.telefono,
};
