import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/polling/polling_controller.dart';
import '../domain/preferencias_notificacion.dart';

/// Persistencia local de las preferencias de notificación.
///
/// No hay endpoint a propósito (07.1 SCR-PROF-08: "Endpoints: Ninguno"), por
/// eso se guardan en [SharedPreferences] igual que el historial de búsqueda.
/// Cada interruptor es una clave propia para que un valor corrupto en una no
/// tumbe el resto de la lectura.
class PreferenciasRepository {
  const PreferenciasRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefijo = 'quickbite_prefs_';

  Future<PreferenciasNotificacion> read() async {
    return PreferenciasNotificacion(
      pedidoNuevo: _leerBool('pedido_nuevo', porDefecto: true),
      cambioEstado: _leerBool('cambio_estado', porDefecto: true),
      asignacion: _leerBool('asignacion', porDefecto: true),
      sistema: _leerBool('sistema', porDefecto: true),
      recordatorio: _leerBool('recordatorio', porDefecto: true),
      sonido: _leerBool('sonido', porDefecto: true),
      vibracion: _leerBool('vibracion', porDefecto: true),
      intervaloActualizacion: Duration(
        seconds: _leerInt(
          'intervalo_segundos',
          porDefecto: FrecuenciaPolling.porDefecto.inSeconds,
        ),
      ),
    );
  }

  Future<void> save(PreferenciasNotificacion prefs) async {
    await _preferences.setBool('${_prefijo}pedido_nuevo', prefs.pedidoNuevo);
    await _preferences.setBool(
      '${_prefijo}cambio_estado',
      prefs.cambioEstado,
    );
    await _preferences.setBool('${_prefijo}asignacion', prefs.asignacion);
    await _preferences.setBool('${_prefijo}sistema', prefs.sistema);
    await _preferences.setBool('${_prefijo}recordatorio', prefs.recordatorio);
    await _preferences.setBool('${_prefijo}sonido', prefs.sonido);
    await _preferences.setBool('${_prefijo}vibracion', prefs.vibracion);
    await _preferences.setInt(
      '${_prefijo}intervalo_segundos',
      prefs.intervaloActualizacion.inSeconds,
    );
  }

  /// Borra solo las claves de preferencias: el historial de búsqueda vive en las
  /// mismas [SharedPreferences] y no debe verse afectado.
  Future<void> clear() async {
    final propias = _preferences
        .getKeys()
        .where((clave) => clave.startsWith(_prefijo))
        .toList();
    for (final clave in propias) {
      await _preferences.remove(clave);
    }
  }

  bool _leerBool(String clave, {required bool porDefecto}) {
    try {
      return _preferences.getBool('$_prefijo$clave') ?? porDefecto;
    } on Object {
      return porDefecto;
    }
  }

  int _leerInt(String clave, {required int porDefecto}) {
    int valor;
    try {
      final guardado = _preferences.getInt('$_prefijo$clave');
      if (guardado == null) return porDefecto;
      valor = guardado;
    } on Object {
      return porDefecto;
    }
    return FrecuenciaPolling.normalizar(
      Duration(seconds: valor),
    ).inSeconds;
  }
}
