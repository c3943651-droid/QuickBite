import 'dart:async';

import 'package:quickbite_mobile/src/core/connectivity/conectividad.dart';

/// Doble de [Conectividad] con el stream controlado a mano.
///
/// El estado de red es cosa del sistema: los tests no pueden depender de la red
/// real, así que el doble expone [emitir] para simular la pérdida y la
/// recuperación de la conexión.
class FakeConectividad implements Conectividad {
  FakeConectividad({this.conectado = true});

  bool conectado;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Cuántas veces se consultó el estado: sirve para comprobar que "Reintentar"
  /// vuelve a preguntar en vez de solo repintar.
  int consultas = 0;

  @override
  Future<bool> hayConexion() async {
    consultas++;
    return conectado;
  }

  @override
  Stream<bool> cambios() => _controller.stream;

  void emitir(bool valor) {
    conectado = valor;
    _controller.add(valor);
  }
}
