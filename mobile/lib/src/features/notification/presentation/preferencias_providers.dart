import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/retry_policy.dart';
import '../data/preferencias_repository.dart';
import '../domain/notification_entities.dart';
import '../domain/preferencias_notificacion.dart';
import '../../search/presentation/search_providers.dart';

final preferenciasRepositoryProvider = Provider<PreferenciasRepository>(
  (ref) => PreferenciasRepository(ref.watch(sharedPreferencesProvider)),
);

/// Preferencia local de notificaciones (07.1 SCR-PROF-08). Es un
/// [AsyncNotifier] porque lee de [SharedPreferences] al entrar; cada cambio se
/// aplica al instante en memoria y se persiste en segundo plano.
final preferenciasNotificacionProvider =
    AsyncNotifierProvider<
      PreferenciasNotificacionNotifier,
      PreferenciasNotificacion
    >(PreferenciasNotificacionNotifier.new, retry: noAutoRetry);

class PreferenciasNotificacionNotifier
    extends AsyncNotifier<PreferenciasNotificacion> {
  @override
  Future<PreferenciasNotificacion> build() {
    return ref.watch(preferenciasRepositoryProvider).read();
  }

  Future<void> actualizarTipo(TipoNotificacion tipo, bool activo) async {
    final actuales = state.value ?? const PreferenciasNotificacion();
    await _guardar(actuales.actualizarTipo(tipo, activo));
  }

  Future<void> cambiarSonido(bool activo) async {
    final actuales = state.value ?? const PreferenciasNotificacion();
    await _guardar(actuales.conSonido(activo));
  }

  Future<void> cambiarVibracion(bool activo) async {
    final actuales = state.value ?? const PreferenciasNotificacion();
    await _guardar(actuales.conVibracion(activo));
  }

  /// Cambia la frecuencia del polling de seguimiento (05#D-01).
  Future<void> cambiarIntervalo(Duration intervalo) async {
    final actuales = state.value ?? const PreferenciasNotificacion();
    await _guardar(actuales.conIntervalo(intervalo));
  }

  Future<void> _guardar(PreferenciasNotificacion prefs) async {
    state = AsyncData(prefs);
    await ref.read(preferenciasRepositoryProvider).save(prefs);
  }
}
