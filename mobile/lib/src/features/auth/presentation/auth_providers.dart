import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/retry_policy.dart';
import '../../../core/session/token_storage.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository_impl.dart';
import '../data/dtos/user_profile_dto.dart';
import '../domain/auth_entities.dart';
import '../domain/auth_repository.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage(const FlutterSecureStorage());
});

final dioProvider = Provider<DioClient>((ref) {
  return DioClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    onRefresh: () => _refreshSession(ref),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dio: ref.watch(dioProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(tokenStorageProvider),
  );
});

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AuthSession?>(
  SessionNotifier.new,
  retry: noAutoRetry,
);

class SessionNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final stored = await repository.restoreSession();
    if (stored == null) {
      return null;
    }
    final user = await _resolveUser();
    if (user == null) {
      await ref.read(tokenStorageProvider).clear();
      return null;
    }
    return AuthSession(
      tokens: AuthTokens(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken,
        expiresIn: stored.expiresIn,
      ),
      user: user,
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.login(email: email, password: password);
      await repository.persistSession(session);
      return session;
    });
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .register(
            nombre: nombre,
            email: email,
            password: password,
            telefono: telefono,
            rol: rol,
          );
      return null;
    });
  }

  Future<void> logout() async {
    final current = state.value;
    try {
      if (current != null) {
        await ref
            .read(authRepositoryProvider)
            .logout(refreshToken: current.tokens.refreshToken);
      } else {
        await ref.read(tokenStorageProvider).clear();
      }
    } on Object {
      // El cierre de sesión local siempre debe completarse, aunque el backend falle.
    }
    state = const AsyncData<AuthSession?>(null);
  }

  Future<AuthUser?> _resolveUser() async {
    try {
      final response = await ref.read(apiClientProvider).get('/users/profile');
      final dto = UserProfileDto.fromJson(
        response.data as Map<String, dynamic>,
      );
      return AuthUser(
        id: dto.id,
        nombre: dto.nombre,
        email: dto.email,
        rol: dto.rol,
      );
    } on Object {
      return null;
    }
  }
}

Future<StoredSession?> _refreshSession(Ref ref) async {
  final stored = await ref.read(tokenStorageProvider).read();
  if (stored == null) {
    return null;
  }
  try {
    final tokens = await ref
        .read(authRepositoryProvider)
        .refresh(refreshToken: stored.refreshToken);
    final session = StoredSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: tokens.expiresIn,
    );
    await ref.read(tokenStorageProvider).save(session);
    return session;
  } on Object {
    return null;
  }
}
