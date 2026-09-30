import 'package:equatable/equatable.dart';

/// Sesión activa del usuario (07.1 SCR-PROF-05, 04 §4.9).
///
/// Cada sesión es un token de refresco no revocado ni expirado. El backend
/// marca `es_actual` comparando el token enviado en `X-Refresh-Token`, así que
/// la distinción entre "esta sesión" y las demás la resuelve la API y no el
/// cliente: [puedeRevocarse] solo refleja esa respuesta.
class SesionUsuario extends Equatable {
  const SesionUsuario({
    required this.id,
    required this.creadoEn,
    required this.expiraEn,
    required this.esActual,
    this.ipOrigen,
    this.userAgent,
  });

  final String id;
  final String? ipOrigen;
  final String? userAgent;

  /// A diferencia del resto, aquí las fechas **son opcionales**: el backend no
  /// las declara obligatorias en 04 §4.9 y una fecha ausente o mal formada no
  /// puede inventarse, así que la vista dice "Sin fecha" en vez de enseñar una
  /// fecha falsa.
  final DateTime? creadoEn;
  final DateTime? expiraEn;
  final bool esActual;

  /// La sesión en curso no se revoca desde aquí: el usuario cierra sesión
  /// desde el perfil (07.1 SCR-PROF-05, "Acciones y efectos").
  bool get puedeRevocarse => !esActual;

  /// Datos que pueden faltar según el cliente que emitió la sesión (04 §4.9
  /// no los declara obligatorios).
  String get dispositivo => userAgent?.trim().isNotEmpty == true
      ? userAgent!.trim()
      : 'Dispositivo desconocido';

  String get direccion =>
      ipOrigen?.trim().isNotEmpty == true ? ipOrigen!.trim() : 'IP desconocida';

  @override
  List<Object?> get props => [
    id,
    ipOrigen,
    userAgent,
    creadoEn,
    expiraEn,
    esActual,
  ];
}
