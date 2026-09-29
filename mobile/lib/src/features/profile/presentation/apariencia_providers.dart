import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/retry_policy.dart';
import '../../search/presentation/search_providers.dart';
import '../data/apariencia_repository.dart';
import '../domain/preferencias_apariencia.dart';

final aparienciaRepositoryProvider = Provider<AparienciaRepository>(
  (ref) => AparienciaRepository(ref.watch(sharedPreferencesProvider)),
);

/// Preferencia local de apariencia (07.1 SCR-PROF-09).
///
/// Es un [AsyncNotifier] y no datos en un `FutureProvider` porque cada cambio se
/// aplica al instante en memoria y se persiste detrás: la pantalla de
/// apariencia se usa precisamente para ver el efecto mientras se elige.
final aparienciaProvider =
    AsyncNotifierProvider<AparienciaNotifier, PreferenciasApariencia>(
      AparienciaNotifier.new,
      retry: noAutoRetry,
    );

class AparienciaNotifier extends AsyncNotifier<PreferenciasApariencia> {
  @override
  Future<PreferenciasApariencia> build() {
    return ref.watch(aparienciaRepositoryProvider).read();
  }

  Future<void> cambiarTema(TemaApp tema) => _guardar(
    (actuales) => actuales.conTema(tema),
  );

  Future<void> cambiarTamanoTexto(TamanoTexto tamano) => _guardar(
    (actuales) => actuales.conTamanoTexto(tamano),
  );

  Future<void> cambiarContraste(Contraste contraste) => _guardar(
    (actuales) => actuales.conContraste(contraste),
  );

  Future<void> cambiarReducirAnimaciones(bool activar) => _guardar(
    (actuales) => actuales.conReducirAnimaciones(activar),
  );

  Future<void> cambiarModoDaltonismo(ModoDaltonismo modo) => _guardar(
    (actuales) => actuales.conModoDaltonismo(modo),
  );

  /// Deja las preferencias como venían de fábrica. Lo usa "Restablecer
  /// preferencias" en Avanzado (07.1 SCR-PROF-14), que es una acción de
  /// mantenimiento y avisa antes de ejecutarse.
  Future<void> restablecer() => _guardar((_) => const PreferenciasApariencia());

  Future<void> _guardar(
    PreferenciasApariencia Function(PreferenciasApariencia actuales) cambio,
  ) async {
    final nuevas = cambio(state.value ?? const PreferenciasApariencia());
    state = AsyncData(nuevas);
    await ref.read(aparienciaRepositoryProvider).save(nuevas);
  }
}
