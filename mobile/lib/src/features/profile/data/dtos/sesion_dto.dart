import 'package:json_annotation/json_annotation.dart';

part 'sesion_dto.g.dart';

/// Lectura tolerante: los datos de una sesión son informativos, así que un
/// campo raro no puede dejar la pantalla de sesiones en error.
String _texto(Object? valor) => valor is String ? valor : '${valor ?? ''}';

String? _textoOpcional(Object? valor) {
  if (valor == null) return null;
  final texto = valor is String ? valor : '$valor';
  return texto.trim().isEmpty ? null : texto;
}

/// `es_actual` ausente o nulo es `false`: una sesión sin ese dato no es la
/// sesión actual, y marcarla como tal dejaría dos filas actives.
bool _booleano(Object? valor) => switch (valor) {
  bool v => v,
  num v => v != 0,
  String v => v.toLowerCase() == 'true',
  _ => false,
};

DateTime? _fechaOpcional(Object? valor) {
  if (valor is! String || valor.isEmpty) return null;
  return DateTime.tryParse(valor);
}

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

  @JsonKey(fromJson: _texto)
  final String id;

  @JsonKey(name: 'ip_origen', fromJson: _textoOpcional)
  final String? ipOrigen;

  @JsonKey(name: 'user_agent', fromJson: _textoOpcional)
  final String? userAgent;

  @JsonKey(name: 'creado_en', fromJson: _fechaOpcional)
  final DateTime? creadoEn;

  @JsonKey(name: 'expira_en', fromJson: _fechaOpcional)
  final DateTime? expiraEn;

  @JsonKey(name: 'es_actual', fromJson: _booleano)
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
