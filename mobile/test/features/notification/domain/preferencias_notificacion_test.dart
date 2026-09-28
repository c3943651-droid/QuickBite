import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/polling/polling_controller.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/domain/preferencias_notificacion.dart';

void main() {
  group('PreferenciasNotificacion (07.1 SCR-PROF-08)', () {
    test('por defecto todos los tipos, sonido y vibración están activos', () {
      const prefs = PreferenciasNotificacion();

      expect(prefs.permite(TipoNotificacion.pedidoNuevo), isTrue);
      expect(prefs.permite(TipoNotificacion.cambioEstado), isTrue);
      expect(prefs.permite(TipoNotificacion.asignacion), isTrue);
      expect(prefs.permite(TipoNotificacion.sistema), isTrue);
      expect(prefs.permite(TipoNotificacion.recordatorio), isTrue);
      expect(prefs.sonido, isTrue);
      expect(prefs.vibracion, isTrue);
      expect(prefs.intervaloActualizacion, FrecuenciaPolling.porDefecto);
    });

    test('actualizarTipo enciende y apaga un tipo', () {
      const prefs = PreferenciasNotificacion();

      final apagado = prefs.actualizarTipo(
        TipoNotificacion.recordatorio,
        false,
      );
      expect(apagado.permite(TipoNotificacion.recordatorio), isFalse);
      expect(apagado.permite(TipoNotificacion.sistema), isTrue);

      final encendido = apagado.actualizarTipo(
        TipoNotificacion.recordatorio,
        true,
      );
      expect(encendido.permite(TipoNotificacion.recordatorio), isTrue);
    });

    test('conSonido y conVibracion alternan sus propios interruptores', () {
      const prefs = PreferenciasNotificacion();

      expect(prefs.conSonido(false).sonido, isFalse);
      expect(prefs.conSonido(false).vibracion, isTrue);
      expect(prefs.conVibracion(false).vibracion, isFalse);
      expect(prefs.conVibracion(false).sonido, isTrue);
    });

    test('conIntervalo normaliza al rango permitido (07 §8.6)', () {
      const prefs = PreferenciasNotificacion();

      expect(
        prefs.conIntervalo(const Duration(seconds: 30)).intervaloActualizacion,
        const Duration(seconds: 30),
      );
      expect(
        prefs.conIntervalo(const Duration(seconds: 1)).intervaloActualizacion,
        FrecuenciaPolling.opciones.first,
      );
      expect(
        prefs
            .conIntervalo(const Duration(hours: 2))
            .intervaloActualizacion,
        FrecuenciaPolling.opciones.last,
      );
    });

    test('los tres valores de frecuencia salen del catálogo canónico', () {
      expect(FrecuenciaPolling.opciones, [
        const Duration(seconds: 10),
        const Duration(seconds: 30),
        const Duration(minutes: 1),
      ]);
    });
  });
}
