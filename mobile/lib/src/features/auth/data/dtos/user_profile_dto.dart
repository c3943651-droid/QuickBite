import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.creadoEn,
    this.ultimoLogin,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? telefono;

  @JsonKey(name: 'creado_en')
  final DateTime? creadoEn;

  @JsonKey(name: 'ultimo_login')
  final DateTime? ultimoLogin;
}
