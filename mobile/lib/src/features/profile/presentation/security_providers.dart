import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/retry_policy.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/seguridad_remote_data_source.dart';
import '../data/seguridad_repository_impl.dart';
import '../domain/seguridad_repository.dart';
import '../domain/sesion_usuario.dart';

final seguridadRepositoryProvider = Provider<SeguridadRepository>((ref) {
  return SeguridadRepositoryImpl(
    SeguridadRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(tokenStorageProvider),
  );
});

/// Sesiones activas del usuario (07.1 SCR-PROF-05). Es un [AsyncNotifier] y no
/// un `FutureProvider` porque revocar actualiza la lista sin volver a pedirla:
/// la fila desaparece al instante y la petición que ya está en vuelo no puede
/// resucitarla.
final sesionesProvider =
    AsyncNotifierProvider<SesionesNotifier, List<SesionUsuario>>(
      SesionesNotifier.new,
      retry: noAutoRetry,
    );

class SesionesNotifier extends AsyncNotifier<List<SesionUsuario>> {
  @override
  Future<List<SesionUsuario>> build() {
    return ref.watch(seguridadRepositoryProvider).fetchSessions();
  }

  /// Revoca una sesión y la quita de la lista.
  ///
  /// El error se deja subir a quien la invocó, que es quien tiene el contexto
  /// para avisar, y la lista no se toca: revocar en falso borraría de la vista
  /// una sesión que sigue abierta en el servidor.
  Future<void> revocar(String id) async {
    final actuales = state.value;
    await ref.read(seguridadRepositoryProvider).revokeSession(id);
    state = AsyncData(
      (actuales ?? const <SesionUsuario>[])
          .where((sesion) => sesion.id != id)
          .toList(),
    );
  }

  Future<void> recargar() async {
    state = await AsyncValue.guard(
      () => ref.read(seguridadRepositoryProvider).fetchSessions(),
    );
  }
}

/// Estado del cambio de contraseña (07.1 SCR-PROF-04). No se modela con
/// [AsyncNotifier] porque su éxito no deja datos que leer: lo único que
/// persiste es [guardado], que la pantalla usa para volver a Seguridad.
@immutable
class CambioPasswordState {
  const CambioPasswordState({
    this.loading = false,
    this.guardado = false,
    this.error,
  });

  final bool loading;
  final bool guardado;
  final Object? error;

  /// Texto para el campo: el backend distingue "la actual no coincide" de
  /// "la nueva no cumple la política" y ambos llegan como 400 (04 §4.3).
  String? get errorMessage => switch (error) {
    ValidationException(:final userMessage) => userMessage,
    _ => null,
  };
}

final cambioPasswordProvider =
    NotifierProvider<CambioPasswordNotifier, CambioPasswordState>(
      CambioPasswordNotifier.new,
    );

class CambioPasswordNotifier extends Notifier<CambioPasswordState> {
  @override
  CambioPasswordState build() => const CambioPasswordState();

  Future<bool> guardar({required String actual, required String nueva}) async {
    state = const CambioPasswordState(loading: true);
    try {
      await ref
          .read(seguridadRepositoryProvider)
          .changePassword(actual: actual, nueva: nueva);
      state = const CambioPasswordState(guardado: true);
      return true;
    } on Object catch (error) {
      state = CambioPasswordState(error: error);
      return false;
    }
  }

  void limpiar() => state = const CambioPasswordState();
}
