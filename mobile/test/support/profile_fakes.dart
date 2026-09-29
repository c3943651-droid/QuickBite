import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/profile/domain/seguridad_repository.dart';
import 'package:quickbite_mobile/src/features/profile/domain/sesion_usuario.dart';

/// Doble de [SeguridadRepository] para las pruebas de las pantallas de
/// seguridad. Registra las escrituras para que cada test afirme el efecto
/// (qué sesión se revocó, qué contraseña se envió) sin inspeccionar la capa
/// de red.
class FakeSeguridadRepository implements SeguridadRepository {
  FakeSeguridadRepository({List<SesionUsuario>? sesiones, this.error})
    : sesiones = List.of(sesiones ?? const <SesionUsuario>[]);

  List<SesionUsuario> sesiones;
  Object? error;

  final List<String> revocadas = [];
  final List<({String actual, String nueva})> cambios = [];

  /// Falla solo al revocar, para ejercitar el error de una acción concreta.
  Object? revokeError;

  @override
  Future<List<SesionUsuario>> fetchSessions() async {
    if (error != null) throw error!;
    return List.unmodifiable(sesiones);
  }

  @override
  Future<void> revokeSession(String id) async {
    if (revokeError != null) throw revokeError!;
    revocadas.add(id);
    sesiones = sesiones.where((s) => s.id != id).toList();
  }

  @override
  Future<void> changePassword({
    required String actual,
    required String nueva,
  }) async {
    if (error != null) throw error!;
    cambios.add((actual: actual, nueva: nueva));
  }
}

SesionUsuario sesion({
  String id = 'sesion-1',
  String? ipOrigen = '203.0.113.7',
  String? userAgent = 'Chrome 141 / Android',
  DateTime? creadoEn,
  DateTime? expiraEn,
  bool esActual = false,
}) {
  return SesionUsuario(
    id: id,
    ipOrigen: ipOrigen,
    userAgent: userAgent,
    creadoEn: creadoEn ?? DateTime.utc(2026, 9, 20, 10),
    expiraEn: expiraEn ?? DateTime.utc(2026, 10, 20, 10),
    esActual: esActual,
  );
}

/// El error que devuelve la API cuando la contraseña actual no coincide
/// (04 §4.3), que la pantalla debe mostrar con su propio texto.
final passwordIncorrecto = ValidationException(
  'La contraseña actual es incorrecta.',
);
