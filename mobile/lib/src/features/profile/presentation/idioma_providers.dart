import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/retry_policy.dart';
import '../../search/presentation/search_providers.dart';
import '../data/idioma_repository.dart';
import '../domain/preferencias_idioma.dart';

final idiomaRepositoryProvider = Provider<IdiomaRepository>(
  (ref) => IdiomaRepository(ref.watch(sharedPreferencesProvider)),
);

/// Idioma y formatos regionales (07.1 SCR-PROF-10).
final idiomaProvider =
    AsyncNotifierProvider<IdiomaNotifier, PreferenciasIdioma>(
      IdiomaNotifier.new,
      retry: noAutoRetry,
    );

class IdiomaNotifier extends AsyncNotifier<PreferenciasIdioma> {
  @override
  Future<PreferenciasIdioma> build() {
    return ref.watch(idiomaRepositoryProvider).read();
  }

  Future<void> cambiarFormatoFecha(FormatoFecha formato) => _guardar(
    (actuales) => actuales.conFormatoFecha(formato),
  );

  Future<void> cambiarFormatoHora(FormatoHora formato) => _guardar(
    (actuales) => actuales.conFormatoHora(formato),
  );

  /// Deja los formatos como venían de fábrica. Lo invoca "Restablecer
  /// preferencias" en Avanzado (07.1 SCR-PROF-14).
  Future<void> restablecer() => _guardar((_) => const PreferenciasIdioma());

  /// Formatea con los formatos vigentes. Se usa desde pantallas que solo tienen
  /// un `BuildContext`, para no tener que observar el provider entero.
  String formatearFechaHora(DateTime momento) =>
      state.value?.formatearFechaHora(momento) ??
      const PreferenciasIdioma().formatearFechaHora(momento);

  Future<void> _guardar(
    PreferenciasIdioma Function(PreferenciasIdioma actuales) cambio,
  ) async {
    final nuevas = cambio(state.value ?? const PreferenciasIdioma());
    state = AsyncData(nuevas);
    await ref.read(idiomaRepositoryProvider).save(nuevas);
  }
}
