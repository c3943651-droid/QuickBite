import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

@JsonSerializable()
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);

  final String email;
  final String password;
}

@JsonSerializable()
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.nombre,
    required this.email,
    required this.password,
    required this.rol,
    this.telefono,
  });

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestDtoToJson(this);

  final String nombre;
  final String email;
  final String password;
  final String? telefono;
  final String rol;
}

@JsonSerializable()
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserSummaryDto user;
}

@JsonSerializable()
class RefreshRequestDto {
  const RefreshRequestDto({required this.refreshToken});

  factory RefreshRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshRequestDtoToJson(this);

  final String refreshToken;
}

@JsonSerializable()
class RefreshResponseDto {
  const RefreshResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshResponseDtoToJson(this);

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

@JsonSerializable()
class UserSummaryDto {
  const UserSummaryDto({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserSummaryDtoToJson(this);

  final String id;
  final String nombre;
  final String email;
  final String rol;
}

@JsonSerializable()
class LogoutRequestDto {
  const LogoutRequestDto({required this.refreshToken});

  factory LogoutRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LogoutRequestDtoToJson(this);

  final String refreshToken;
}

@JsonSerializable()
class MessageResponseDto {
  const MessageResponseDto({this.message});

  factory MessageResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MessageResponseDtoToJson(this);

  final String? message;
}
