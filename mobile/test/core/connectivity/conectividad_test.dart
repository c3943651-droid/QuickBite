import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/connectivity/conectividad.dart';

void main() {
  group('ConnectivityPlusConectividad', () {
    late FakeConnectivityPlatform platform;

    setUp(() {
      platform = FakeConnectivityPlatform();
      ConnectivityPlatform.instance = platform;
    });

    test('hayConexion es true con wifi', () async {
      platform.actual = [ConnectivityResult.wifi];

      final conectividad = ConnectivityPlusConectividad();

      expect(await conectividad.hayConexion(), isTrue);
    });

    test('hayConexion es true con datos moviles', () async {
      platform.actual = [ConnectivityResult.mobile];

      final conectividad = ConnectivityPlusConectividad();

      expect(await conectividad.hayConexion(), isTrue);
    });

    test('hayConexion es false si el unico resultado es none', () async {
      platform.actual = [ConnectivityResult.none];

      final conectividad = ConnectivityPlusConectividad();

      expect(await conectividad.hayConexion(), isFalse);
    });

    test('cambios normaliza a booleano', () async {
      final conectividad = ConnectivityPlusConectividad();

      // El stream de la plataforma es broadcast: si se emitiera antes de
      // suscribirse, los eventos se perderían, así que la expectativa se
      // registra primero.
      final esperado = expectLater(
        conectividad.cambios().take(3),
        emitsInOrder([isTrue, isFalse, isTrue]),
      );

      platform.emitir([ConnectivityResult.wifi]);
      platform.emitir([ConnectivityResult.none]);
      platform.emitir([ConnectivityResult.mobile, ConnectivityResult.vpn]);

      await esperado;
    });
  });

  group('proveedor de conectividad', () {
    test('expone la implementacion de connectivity_plus', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      expect(
        contenedor.read(conectividadProvider),
        isA<ConnectivityPlusConectividad>(),
      );
    });
  });
}

class FakeConnectivityPlatform extends ConnectivityPlatform {
  FakeConnectivityPlatform({List<ConnectivityResult>? actual})
    : actual = actual ?? [ConnectivityResult.wifi];

  List<ConnectivityResult> actual;
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => actual;

  void emitir(List<ConnectivityResult> estados) {
    actual = estados;
    _controller.add(estados);
  }

  Future<void> cerrar() => _controller.close();
}
