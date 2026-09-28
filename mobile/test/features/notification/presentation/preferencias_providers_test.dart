import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/polling/polling_controller.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/domain/preferencias_notificacion.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/preferencias_providers.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_tracking_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> contenedorCon([
    Map<String, Object> guardadas = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(guardadas);
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = InMemoryTokenStorage();
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('preferencias de notificación (07.1 SCR-PROF-08)', () {
    test('carga los valores por defecto sin datos guardados', () async {
      final container = await contenedorCon();

      final prefs = await container.read(
        preferenciasNotificacionProvider.future,
      );

      expect(prefs, const PreferenciasNotificacion());
    });

    test('un interruptor cambia el estado y se persiste', () async {
      final container = await contenedorCon();
      await container.read(preferenciasNotificacionProvider.future);

      await container
          .read(preferenciasNotificacionProvider.notifier)
          .actualizarTipo(TipoNotificacion.recordatorio, false);

      final prefs = container.read(preferenciasNotificacionProvider).value;
      expect(prefs!.permite(TipoNotificacion.recordatorio), isFalse);
      expect(
        (await container.read(preferenciasNotificacionProvider.future))
            .permite(TipoNotificacion.recordatorio),
        isFalse,
      );
    });

    test('la frecuencia elegida alimenta el polling del seguimiento', () async {
      final container = await contenedorCon({});
      await container.read(preferenciasNotificacionProvider.future);

      expect(
        container.read(intervaloPollingProvider),
        FrecuenciaPolling.porDefecto,
      );

      await container
          .read(preferenciasNotificacionProvider.notifier)
          .cambiarIntervalo(const Duration(minutes: 1));

      expect(
        container.read(intervaloPollingProvider),
        const Duration(minutes: 1),
      );
    });

    test('un intervalo guardado fuera de rango se acota al leer', () async {
      final container = await contenedorCon({
        'quickbite_prefs_intervalo_segundos': 5,
      });
      await container.read(preferenciasNotificacionProvider.future);

      expect(
        container.read(intervaloPollingProvider),
        FrecuenciaPolling.opciones.first,
      );
    });
  });
}
