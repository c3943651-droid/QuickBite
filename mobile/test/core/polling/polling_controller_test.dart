import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/polling/polling_controller.dart';

void main() {
  group('FrecuenciaPolling', () {
    test('por defecto son 10 segundos', () {
      expect(FrecuenciaPolling.porDefecto, const Duration(seconds: 10));
    });

    test('ofrece las frecuencias de preferencias', () {
      expect(FrecuenciaPolling.opciones, [
        const Duration(seconds: 10),
        const Duration(seconds: 30),
        const Duration(minutes: 1),
      ]);
    });

    test('acota la preferencia al rango permitido', () {
      expect(
        FrecuenciaPolling.normalizar(const Duration(seconds: 1)),
        const Duration(seconds: 10),
      );
      expect(
        FrecuenciaPolling.normalizar(const Duration(hours: 1)),
        const Duration(minutes: 1),
      );
      expect(
        FrecuenciaPolling.normalizar(const Duration(seconds: 30)),
        const Duration(seconds: 30),
      );
    });
  });

  group('PollingController', () {
    test('consulta al entrar a la pantalla y repite cada intervalo', () async {
      var consultas = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 30),
        onTick: () async {
          consultas++;
          return true;
        },
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      controller.stop();

      expect(consultas, greaterThan(2));
    });

    test('se detiene al salir de la pantalla', () async {
      var consultas = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 30),
        onTick: () async {
          consultas++;
          return true;
        },
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      controller.stop();
      final alDetener = consultas;
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(controller.isRunning, isFalse);
      expect(consultas, alDetener);
    });

    test('se pausa en segundo plano y reanuda al volver', () async {
      var consultas = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 30),
        onTick: () async {
          consultas++;
          return true;
        },
      )..setVisible(false);

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(consultas, 0, reason: 'no consulta con la app oculta');

      controller.setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      controller.stop();

      expect(consultas, greaterThan(0));
    });

    test('deja de consultar cuando el estado es final', () async {
      var consultas = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 20),
        onTick: () async {
          consultas++;
          return false; // entregado o cancelado
        },
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(consultas, 1);
      expect(controller.isRunning, isFalse);
      expect(controller.pausadoPorErrores, isFalse);
    });

    test('ante errores espera cada vez más antes de reintentar', () async {
      final esperas = <Duration>[];
      DateTime? anterior;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 20),
        onTick: () async {
          final ahora = DateTime.now();
          if (anterior != null) esperas.add(ahora.difference(anterior!));
          anterior = ahora;
          throw Exception('sin red');
        },
        maxIntentos: 2,
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      controller.stop();

      expect(esperas.length, greaterThanOrEqualTo(2));
      expect(esperas[1], greaterThan(esperas[0]));
    });

    test('tras agotar los reintentos se pausa y avisa', () async {
      var intentos = 0;
      var avisado = false;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 10),
        onTick: () async {
          intentos++;
          throw Exception('sin red');
        },
        onPausa: () => avisado = true,
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(intentos, 4, reason: 'un intento más tres reintentos');
      expect(controller.isRunning, isFalse);
      expect(controller.pausadoPorErrores, isTrue);
      expect(avisado, isTrue);
    });

    test('el error se reporta con el número de intento', () async {
      final errores = <int>[];
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 10),
        onTick: () async => throw Exception('sin red'),
        onError: (_, intento) => errores.add(intento),
        maxIntentos: 1,
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(errores, [1, 2]);
    });

    test('reanudar a mano limpia el error y vuelve a consultar', () async {
      var intentos = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 20),
        onTick: () async {
          intentos++;
          if (intentos <= 2) throw Exception('sin red');
          return true;
        },
        maxIntentos: 1,
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(controller.pausadoPorErrores, isTrue);

      controller.reanudar();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      controller.stop();

      expect(controller.pausadoPorErrores, isFalse);
      expect(intentos, greaterThan(2));
    });

    test('un tick correcto reinicia el contador de errores', () async {
      var intentos = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 20),
        onTick: () async {
          intentos++;
          if (intentos == 1) throw Exception('sin red');
          return true;
        },
        maxIntentos: 1,
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(controller.pausadoPorErrores, isFalse);
      expect(intentos, greaterThan(1));
    });

    test('detener no deja el timer vivo para consultar más', () async {
      var consultas = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 20),
        onTick: () async {
          consultas++;
          return true;
        },
      );

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      controller.stop();
      final alDetener = consultas;
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(consultas, alDetener);
      expect(consultas, lessThan(5));
    });

    test('arranca invisible y solo consulta cuando se muestra', () async {
      var consultas = 0;
      final controller = PollingController(
        intervalo: const Duration(milliseconds: 20),
        onTick: () async {
          consultas++;
          return true;
        },
      )..setVisible(false);

      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(consultas, 0);

      controller.setVisible(true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      controller.stop();
      expect(consultas, greaterThan(0));
    });
  });
}
