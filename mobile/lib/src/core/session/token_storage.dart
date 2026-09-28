import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

abstract class TokenStorage {
  Future<StoredSession?> read();
  Future<void> save(StoredSession session);
  Future<void> clear();
  Future<String?> readAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'quickbite_access_token';
  static const _refreshKey = 'quickbite_refresh_token';
  static const _expiresKey = 'quickbite_expires_in';

  @override
  Future<StoredSession?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) {
      return null;
    }
    final expires = await _storage.read(key: _expiresKey);
    return StoredSession(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: int.tryParse(expires ?? '') ?? 0,
    );
  }

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<void> save(StoredSession session) async {
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
    await _storage.write(key: _expiresKey, value: session.expiresIn.toString());
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresKey);
  }
}
