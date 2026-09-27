import '../../../core/session/token_storage.dart';
import 'auth_entities.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  });

  /// Solicita el enlace de recuperación. No revela si el correo existe (05#D-04),
  /// así que no devuelve nada: la respuesta siempre es la misma.
  Future<void> forgotPassword({required String email});

  /// Restablece la contraseña con el token recibido por correo.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<AuthTokens> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<StoredSession?> restoreSession();

  Future<void> persistSession(AuthSession session);

  /// Perfil completo del usuario autenticado (04 §4.1).
  Future<UserProfile> fetchProfile();

  /// Actualiza los datos personales. El contrato los declara opcionales: un
  /// valor vacío se envía como `null` para no mandar strings en blanco (04 §4.2).
  Future<UserProfile> updateProfile({String? nombre, String? telefono});
}
