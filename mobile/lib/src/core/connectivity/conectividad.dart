import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de red del dispositivo.
///
/// El plugin solo sabe de radios, no de internet real, pero para el usuario
/// "no hay señal" y "hay señal pero la llamada falla" se resuelven igual: el
/// error de red ya lo traduce `ErrorMapper` a `NetworkException`, y este
/// servicio solo evita que la app parezca viva cuando el dispositivo está
/// claramente desconectado (07.1 SCR-COM-01).
abstract interface class Conectividad {
  /// Estado actual, sin esperar cambios.
  Future<bool> hayConexion();

  /// Cambios de estado, normalizados a `true` = hay conexión.
  Stream<bool> cambios();
}

class ConnectivityPlusConectividad implements Conectividad {
  ConnectivityPlusConectividad([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hayConexion() async => _normaliza(await _connectivity.checkConnectivity());

  @override
  Stream<bool> cambios() =>
      _connectivity.onConnectivityChanged.map(_normaliza).distinct();

  static bool _normaliza(List<ConnectivityResult> estados) =>
      estados.any((e) => e != ConnectivityResult.none);
}

final conectividadProvider = Provider<Conectividad>(
  (ref) => ConnectivityPlusConectividad(),
);

/// Estado de conexión observable para la interfaz.
///
/// Arranca en `true` (conexión) a propósito: mostrar el aviso de "sin
/// conexión" antes de la primera lectura de red daría un parpadeo falso en cada
/// arranque. Si el dispositivo realmente está sin red, el primer evento del
/// plugin corrige el valor en cuanto llega.
final conexionProvider = StreamProvider<bool>((ref) async* {
  final conectividad = ref.watch(conectividadProvider);
  yield await conectividad.hayConexion();
  yield* conectividad.cambios();
});
