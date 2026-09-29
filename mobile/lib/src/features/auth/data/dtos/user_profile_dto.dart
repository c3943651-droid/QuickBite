import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

/// Perfil tal como lo devuelve la API (04 §4.1).
///
/// El mapeo es **tolerante a propósito**: el cast estricto que genera
/// `json_serializable` (`json['nombre'] as String`) revienta con `TypeError` en
/// cuanto el servidor manda un campo nulo o lo omite, y entonces la pantalla de
/// perfil se cae entera. Ningún campo de la cabecera es imprescindible para
/// *mostrar* la pantalla, así que un dato que falta se degrada a vacío y la
/// vista decide qué pintar.
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

  @JsonKey(fromJson: _texto)
  final String id;

  @JsonKey(fromJson: _texto)
  final String nombre;

  @JsonKey(fromJson: _texto)
  final String email;

  @JsonKey(fromJson: _texto)
  final String rol;

  @JsonKey(fromJson: _textoOpcional)
  final String? telefono;

  @JsonKey(name: 'creado_en', fromJson: _fechaOpcional)
  final DateTime? creadoEn;

  @JsonKey(name: 'ultimo_login', fromJson: _fechaOpcional)
  final DateTime? ultimoLogin;
}

/// Texto obligatorio: si llega otro tipo (un número en `id`, por ejemplo) se
/// convierte; si no llega nada, queda vacío.
String _texto(Object? valor) => valor is String ? valor : '${valor ?? ''}';

/// Texto opcional: vacío y `null` se equiparan, para que la vista no tenga que
/// distinguir entre "sin teléfono" y "con un teléfono vacío".
String? _textoOpcional(Object? valor) {
  if (valor == null) return null;
  final texto = valor is String ? valor : '$valor';
  return texto.trim().isEmpty ? null : texto;
}

/// Fecha opcional: un `creado_en` mal formado no puede tumbar el perfil entero,
/// se pierde esa fecha y el resto de la pantalla sigue en pie.
DateTime? _fechaOpcional(Object? valor) {
  if (valor is! String || valor.isEmpty) return null;
  return DateTime.tryParse(valor);
}

@JsonSerializable()
class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({this.nombre, this.telefono});

  factory UpdateProfileRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileRequestDtoToJson(this);

  final String? nombre;
  final String? telefono;
}
