import 'package:quickbite_mobile/src/core/session/token_storage.dart';

/// TokenStorage en memoria para tests: registra las escrituras para poder
/// afirmar que la renovación persistió los tokens nuevos.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({
    this.accessToken,
    this.refreshToken,
    this.expiresIn = 3600,
  });

  String? accessToken;
  String? refreshToken;
  int expiresIn;

  int clearCalls = 0;
  int saveCalls = 0;
  final List<StoredSession> saved = [];

  bool get isEmpty => accessToken == null && refreshToken == null;

  @override
  Future<StoredSession?> read() async {
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    return StoredSession(
      accessToken: accessToken!,
      refreshToken: refreshToken!,
      expiresIn: expiresIn,
    );
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> save(StoredSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
    expiresIn = session.expiresIn;
    saveCalls++;
    saved.add(session);
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    clearCalls++;
  }
}
