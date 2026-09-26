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

  Future<AuthTokens> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<StoredSession?> restoreSession();

  Future<void> persistSession(AuthSession session);
}
