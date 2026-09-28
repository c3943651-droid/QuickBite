import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/polling/polling_controller.dart';
import 'package:quickbite_mobile/src/features/notification/data/preferencias_repository.dart';
import 'package:quickbite_mobile/src/features/notification/domain/preferencias_notificacion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferenciasRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = PreferenciasRepository(await SharedPreferences.getInstance());
  });

  group('PreferenciasRepository (SCR-PROF-08, todo local)', () {
    test('sin datos guardados devuelve los valores por defecto', () async {
      final prefs = await repository.read();

      expect(prefs, const PreferenciasNotificacion());
      expect(prefs.intervaloActualizacion, FrecuenciaPolling.porDefecto);
    });

    test('guarda y relee cada interruptor y la frecuencia', () async {
      const custom = PreferenciasNotificacion(
        pedidoNuevo: false,
        cambioEstado: false,
        asignacion: false,
        sistema: true,
        recordatorio: false,
        sonido: false,
        vibracion: false,
        intervaloActualizacion: Duration(seconds: 30),
      );

      await repository.save(custom);

      expect(await repository.read(), custom);
    });

    test('el intervalo se normaliza al escribir y al leer', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_prefs_intervalo_segundos': 3600,
      });
      final conIntervaloBruto = PreferenciasRepository(
        await SharedPreferences.getInstance(),
      );

      final leidas = await conIntervaloBruto.read();
      expect(leidas.intervaloActualizacion, FrecuenciaPolling.opciones.last);

      await conIntervaloBruto.save(
        const PreferenciasNotificacion(
          intervaloActualizacion: Duration(seconds: 2),
        ),
      );
      expect(
        (await conIntervaloBruto.read()).intervaloActualizacion,
        FrecuenciaPolling.opciones.first,
      );
    });

    test('un booleano guardado con otro tipo no rompe la lectura', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_prefs_sonido': 'sí',
      });
      final conTipoInvalido = PreferenciasRepository(
        await SharedPreferences.getInstance(),
      );

      final leidas = await conTipoInvalido.read();

      expect(leidas.sonido, isTrue);
    });

    test('restablecer deja los valores por defecto', () async {
      await repository.save(
        const PreferenciasNotificacion(
          sonido: false,
          intervaloActualizacion: Duration(minutes: 1),
        ),
      );

      await repository.clear();

      expect(await repository.read(), const PreferenciasNotificacion());
    });
  });
}
