// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      telefono: json['telefono'] as String?,
      creadoEn: json['creado_en'] == null
          ? null
          : DateTime.parse(json['creado_en'] as String),
      ultimoLogin: json['ultimo_login'] == null
          ? null
          : DateTime.parse(json['ultimo_login'] as String),
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
