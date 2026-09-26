import '../../../core/session/token_storage.dart';
import '../domain/auth_entities.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final dto = await _remote.login(email: email, password: password);
    return AuthSession(
      tokens: AuthTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
        expiresIn: dto.expiresIn,
      ),
      user: AuthUser(
        id: dto.user.id,
        nombre: dto.user.nombre,
        email: dto.user.email,
        rol: dto.user.rol,
      ),
    );
  }

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {
    await _remote.register(
      nombre: nombre,
      email: email,
      password: password,
      telefono: telefono,
      rol: rol,
    );
  }

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async {
    final dto = await _remote.refresh(refreshToken: refreshToken);
    return AuthTokens(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      expiresIn: dto.expiresIn,
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      await _remote.logout(refreshToken: refreshToken);
    } finally {
      await clearSession();
    }
  }

  @override
  Future<StoredSession?> restoreSession() => _tokenStorage.read();

  @override
  Future<void> persistSession(AuthSession session) {
    return _tokenStorage.save(
      StoredSession(
        accessToken: session.tokens.accessToken,
        refreshToken: session.tokens.refreshToken,
        expiresIn: session.tokens.expiresIn,
      ),
    );
  }

  Future<void> clearSession() => _tokenStorage.clear();
}
