import 'package:json_annotation/json_annotation.dart';

part 'sesion_dto.g.dart';

/// Sesión tal como la devuelve la API (04 §4.9). Los nombres llegan en
/// snake_case porque el backend los serializa con `[JsonPropertyName]`.
@JsonSerializable()
class SesionDto {
  const SesionDto({
    required this.id,
    required this.creadoEn,
    required this.expiraEn,
    required this.esActual,
    this.ipOrigen,
    this.userAgent,
  });

  factory SesionDto.fromJson(Map<String, dynamic> json) =>
      _$SesionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SesionDtoToJson(this);

  final String id;

  @JsonKey(name: 'ip_origen')
  final String? ipOrigen;

  @JsonKey(name: 'user_agent')
  final String? userAgent;

  @JsonKey(name: 'creado_en')
  final DateTime creadoEn;

  @JsonKey(name: 'expira_en')
  final DateTime expiraEn;

  @JsonKey(name: 'es_actual')
  final bool esActual;
}

@JsonSerializable()
class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestDtoToJson(this);

  final String currentPassword;
  final String newPassword;
}
