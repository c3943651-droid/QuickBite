import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
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

/// Adapter de transporte. `null` deja que `Dio` use el suyo por defecto; los
/// tests lo sobrescriben con un doble para cubrir a la vez el cliente
/// principal y el de autenticación, sin mutar el `Dio` a mano.
final httpClientAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

final dioProvider = Provider<DioClient>((ref) {
  return DioClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    onRefresh: () => _refreshSession(ref),
    onSessionInvalid: () => _expireSession(ref),
    httpClientAdapter: ref.watch(httpClientAdapterProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dio: ref.watch(dioProvider).dio);
});

/// Cliente de los endpoints de autenticación, con su propio `Dio` y **sin**
/// `AuthInterceptor`.
///
/// Además de evitar el bucle de recursión, aísla la renovación del
/// interceptor que la dispara: si `/auth/refresh` volviera a pasar por
/// `dioProvider`, la cadena `dioProvider → onRefresh → authRepositoryProvider
/// → apiClientProvider → dioProvider` lanzaría `CircularDependencyError` y la
/// renovación transparente no ocurriría nunca.
final authApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(dio: buildDio(config, ref.watch(httpClientAdapterProvider)));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(authApiClientProvider)),
    ref.watch(tokenStorageProvider),
  );
});

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AuthSession?>(
  SessionNotifier.new,
  retry: noAutoRetry,
);

/// Motivo por el que una sesión activa dejó de ser válida durante el uso.
/// Distingue la expiración por renovación fallida (que debe avisar al usuario,
/// SCR-COM-03) de un arranque sin tokens o de un logout voluntario.
enum SessionExpiry { none, refreshFailed }

final sessionExpiryProvider =
    NotifierProvider<SessionExpiryNotifier, SessionExpiry>(
      SessionExpiryNotifier.new,
    );

class SessionExpiryNotifier extends Notifier<SessionExpiry> {
  @override
  SessionExpiry build() => SessionExpiry.none;

  void markRefreshFailed() => state = SessionExpiry.refreshFailed;

  void reset() => state = SessionExpiry.none;
}

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

  /// Invalida la sesión en curso sin haberlo pedido el usuario. El motivo
  /// queda en [sessionExpiryProvider] para que la app avise (SCR-COM-03).
  void expire() {
    state = const AsyncData<AuthSession?>(null);
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
    ref.read(sessionExpiryProvider.notifier).reset();
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

/// Perfil del usuario autenticado (07.1 SCR-PROF-01/02). El refresh manual
/// se dispara desde el propio hub con `ref.invalidate`, así que la pantalla no
/// necesita un notifier con estado propio.
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(authRepositoryProvider).fetchProfile();
});

/// Estado de `PUT /users/profile`. La pantalla de edición lo consume con
/// `ref.listen`: `saved` marca el éxito y provoca volver al hub (SCR-PROF-02).
@immutable
class ProfileEditState {
  const ProfileEditState({
    this.loading = false,
    this.saved = false,
    this.error,
  });

  final bool loading;
  final bool saved;
  final Object? error;
}

final profileEditProvider =
    NotifierProvider<ProfileEditNotifier, ProfileEditState>(
      ProfileEditNotifier.new,
    );

class ProfileEditNotifier extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  Future<bool> save({String? nombre, String? telefono}) async {
    state = const ProfileEditState(loading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(nombre: nombre, telefono: telefono);
      ref.invalidate(userProfileProvider);
      state = const ProfileEditState(saved: true);
      return true;
    } on Object catch (error) {
      state = ProfileEditState(error: error);
      return false;
    }
  }
}

/// Estado del flujo de recuperación de contraseña (07.1 SCR-AUTH-04/05).
///
/// El envío no se modela con `AsyncNotifier` porque su resultado no se guarda:
/// solo importa si terminó, y el texto que se muestra es siempre el mismo
/// (05#D-04). [sent] permite que la pantalla cambie de formulario a confirmación.
@immutable
class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.loading = false,
    this.sent = false,
    this.error,
  });

  final bool loading;
  final bool sent;
  final Object? error;

  bool get isFailure => error != null;
}

final passwordRecoveryProvider =
    NotifierProvider<PasswordRecoveryNotifier, PasswordRecoveryState>(
      PasswordRecoveryNotifier.new,
    );

class PasswordRecoveryNotifier extends Notifier<PasswordRecoveryState> {
  @override
  PasswordRecoveryState build() => const PasswordRecoveryState();

  Future<void> requestLink({required String email}) async {
    state = const PasswordRecoveryState(loading: true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
      state = const PasswordRecoveryState(sent: true);
    } on ValidationException {
      state = const PasswordRecoveryState(sent: true);
    } on Object catch (error) {
      state = PasswordRecoveryState(error: error);
    }
  }

  Future<bool> submitNewPassword({
    required String token,
    required String newPassword,
  }) async {
    state = const PasswordRecoveryState(loading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, newPassword: newPassword);
      state = const PasswordRecoveryState(sent: true);
      return true;
    } on Object catch (error) {
      state = PasswordRecoveryState(error: error);
      return false;
    }
  }

  void clear() => state = const PasswordRecoveryState();
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
    _expireSession(ref);
    return null;
  }
}

/// Publica la sesión como nula tras una renovación irreparable. Sin esto el
/// `sessionProvider` seguiría anunciando una sesión viva y el usuario
/// quedaría atrapado en la app con peticiones que siempre devuelven 401.
void _expireSession(Ref ref) {
  ref.read(sessionExpiryProvider.notifier).markRefreshFailed();
  ref.read(sessionProvider.notifier).expire();
}

/// Puente Riverpod → go_router. `GoRouter` solo reevalúa su guard cuando su
/// `refreshListenable` notifica, así que los cambios de sesión deben
/// traducirse a `notifyListeners()` para que el redirect reaccione solo.
final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(sessionProvider, (_, _) => notifier.refresh());
  ref.listen(sessionExpiryProvider, (_, _) => notifier.refresh());
  return notifier;
});

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
