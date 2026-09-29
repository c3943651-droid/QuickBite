import 'sesion_usuario.dart';

/// Endpoints de seguridad de la cuenta (04 §4.3, §4.9, §4.10).
///
/// No cuelga de [AuthRepository] a propósito: el login, el registro y la
/// recuperación viven en `features/auth` porque comparten sesión, token y ciclo
/// de vida con el JWT. Estas operaciones, en cambio, son ajustes de la cuenta y
/// siguen la misma regla que `features/address`: su propia capa de datos sobre
/// los endpoints `/users/*` que les corresponden.
abstract interface class SeguridadRepository {
  /// Sesiones activas del usuario, incluida la actual (04 §4.9).
  Future<List<SesionUsuario>> fetchSessions();

  /// Revoca una sesión. La actual no se puede revocar desde aquí (04 §4.10).
  Future<void> revokeSession(String id);

  /// Cambia la contraseña del usuario autenticado (04 §4.3). El backend
  /// responde 400 si la actual no coincide o la nueva no cumple la política,
  /// así que el error llega como [ValidationException].
  Future<void> changePassword({required String actual, required String nueva});
}
