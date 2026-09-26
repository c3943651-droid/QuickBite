// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequestDto _$RegisterRequestDtoFromJson(Map<String, dynamic> json) =>
    RegisterRequestDto(
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      rol: json['rol'] as String,
      telefono: json['telefono'] as String?,
    );

Map<String, dynamic> _$RegisterRequestDtoToJson(RegisterRequestDto instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'email': instance.email,
      'password': instance.password,
      'telefono': instance.telefono,
      'rol': instance.rol,
    };

AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) =>
    AuthResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      user: UserSummaryDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseDtoToJson(AuthResponseDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'user': instance.user,
    };

RefreshRequestDto _$RefreshRequestDtoFromJson(Map<String, dynamic> json) =>
    RefreshRequestDto(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$RefreshRequestDtoToJson(RefreshRequestDto instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

RefreshResponseDto _$RefreshResponseDtoFromJson(Map<String, dynamic> json) =>
    RefreshResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
    );

Map<String, dynamic> _$RefreshResponseDtoToJson(RefreshResponseDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
    };

UserSummaryDto _$UserSummaryDtoFromJson(Map<String, dynamic> json) =>
    UserSummaryDto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
    );

Map<String, dynamic> _$UserSummaryDtoToJson(UserSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'email': instance.email,
      'rol': instance.rol,
    };

LogoutRequestDto _$LogoutRequestDtoFromJson(Map<String, dynamic> json) =>
    LogoutRequestDto(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$LogoutRequestDtoToJson(LogoutRequestDto instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

MessageResponseDto _$MessageResponseDtoFromJson(Map<String, dynamic> json) =>
    MessageResponseDto(message: json['message'] as String?);

Map<String, dynamic> _$MessageResponseDtoToJson(MessageResponseDto instance) =>
    <String, dynamic>{'message': instance.message};
