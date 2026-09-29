import 'dart:async';

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
import '../data/dtos/auth_dtos.dart';
import '../data/dtos/user_profile_dto.dart';
import '../domain/auth_entities.dart';
import '../domain/auth_repository.dart';

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
    onRefresh: () => ref.read(refreshTokensProvider.future),
    // Solo se marca la expiración: cerrar la sesión lo hace quien la observa
    // (ver `routerRefreshProvider`). Leer `sessionProvider` desde aquí lanzaría
    // `CircularDependencyError`, porque `sessionProvider` llega a
    // `apiClientProvider` → `dioProvider`, que es justo este provider.
    onSessionInvalid: () =>
        ref.read(sessionExpiryProvider.notifier).markRefreshFailed(),
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

/// El datasource usa **dos** clientes a propósito:
///
/// - `apiClientProvider` (con `AuthInterceptor`) para lo que necesita token:
///   `GET/PUT /users/profile`. Con un solo cliente, el perfil salía sin
///   cabecera `Authorization`, el backend respondía 401 y —al no pasar por el
///   interceptor— nadie limpiaba la sesión: la pantalla se quedaba en error
///   con un "Reintentar" que no podía arreglar nada.
/// - `authApiClientProvider` (sin interceptor) para `/auth/*`, porque el refresh
///   no puede pasar por el interceptor que lo dispara.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(
      ref.watch(apiClientProvider),
      authClient: ref.watch(authApiClientProvider),
    ),
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
  /// La sesión actual quedó inservible: un `build()` que esté en curso no puede
  /// resucitarla.
  ///
  /// Hace falta porque restaurar la sesión pide `GET /users/profile` para
  /// resolver el usuario, y esa misma llamada puede venir con un 401 que
  /// dispara [expire]. Sin esta marca, el `build` terminaba devolviendo la
  /// sesión caducada y la app se quedaba dentro con peticiones que siempre
  ///Responderían 401.
  bool _expirada = false;

  @override
  Future<AuthSession?> build() async {
    // La capa HTTP solo puede avisar de que el refresh falló (leer este
    // provider desde `dioProvider` cerraría un ciclo de dependencias); cerrar la
    // sesión se hace aquí, que es quien la posee. El listener vive en `build`
    // para que exista aunque nadie haya creado todavía el router.
    ref.listen(sessionExpiryProvider, (_, next) {
      if (next == SessionExpiry.refreshFailed) {
        expire();
      }
    });
    final repository = ref.watch(authRepositoryProvider);
    final stored = await repository.restoreSession();
    if (stored == null || _expirada) {
      return null;
    }
    final user = await _resolveUser();
    if (user == null || _expirada) {
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
    // Volver a entrar limpia cualquier expiración previa: si no, el login
    // following a un 401 volvería a mostrar "Tu sesión ha expirado".
    _expirada = false;
    ref.read(sessionExpiryProvider.notifier).reset();
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
  ///
  /// No borra los tokens: quien los encontró inválidos es el interceptor, y ya
  /// los limpia. Aquí solo se cierra la sesión en memoria para que el guard
  /// redirija a `/login`.
  void expire() {
    _expirada = true;
    state = const AsyncData<AuthSession?>(null);
  }

  Future<void> logout() async {
    _expirada = false;
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
///
/// `noAutoRetry` es obligatorio: sin él, riverpod 3 reintenta solo y el hub se
/// queda girando en "cargando" sin llegar a mostrar ni el error ni el botón
/// "Reintentar" (ver `core/retry_policy.dart`).
final userProfileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.watch(authRepositoryProvider).fetchProfile(),
  retry: noAutoRetry,
);

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

/// Renovación de tokens (SCR-COM-03, 07.3 H0.1).
///
/// Es un provider propio y **no** usa `authRepositoryProvider` a propósito: lo
/// dispara el `AuthInterceptor` que se está construyéndose, y como el
/// repositorio de perfil depende de `apiClientProvider` (que a su vez depende
/// de `dioProvider`), pasar por él cerraría el ciclo
/// `dioProvider → onRefresh → authRepository → apiClient → dioProvider`. Con el
/// ciclo cerrado, riverpod lanza `CircularDependencyError`, el refresh falla y
/// el interceptor expira la sesión en cada petición.
///
/// Aquí solo depende de `authApiClientProvider` (sin interceptor, por diseño) y
/// del almacenamiento, así que la renovación sí ocurre.
///
/// `retry: noAutoRetry` es obligatorio: con el reintento automático de riverpod
/// 3, `ref.read(refreshTokensProvider.future)` **no termina nunca** cuando la
/// renovación falla, y el interceptor se queda colgado en `await` sin llegar a
/// expirar la sesión. La persona se queda mirando la pantalla de error del
/// endpoint que falló, con un "Reintentar" que no arregla nada.
final refreshTokensProvider = FutureProvider<StoredSession>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  final stored = await storage.read();
  if (stored == null) {
    throw StateError('No hay sesión guardada que renovar.');
  }
  final response = await ref
      .read(authApiClientProvider)
      .post('/auth/refresh', data: {'refreshToken': stored.refreshToken});
  // `POST /auth/refresh` no devuelve el usuario, solo los tokens nuevos: por eso
  // se parsea `RefreshResponseDto` y no el sobre de `AuthResponseDto`.
  final dto = RefreshResponseDto.fromJson(
    response.data as Map<String, dynamic>,
  );
  final renewed = StoredSession(
    accessToken: dto.accessToken,
    refreshToken: dto.refreshToken,
    expiresIn: dto.expiresIn,
  );
  await storage.save(renewed);
  return renewed;
}, retry: noAutoRetry);

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
