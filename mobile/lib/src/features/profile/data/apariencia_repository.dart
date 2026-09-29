import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preferencias_apariencia.dart';

/// Persistencia local de las preferencias de apariencia (07.1 SCR-PROF-09).
///
/// Sin endpoint a propósito: son ajustes del dispositivo, no de la cuenta, así
/// que sobreviven a un cierre de sesión y se resuelven sin red. Cada valor es
/// una clave propia para que uno corrupto no tumbe el resto de la lectura, y se
/// normaliza al catálogo porque un enum desconocido en una versión anterior no
/// puede dejar la pantalla sin selección.
class AparienciaRepository {
  const AparienciaRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefijo = 'quickbite_apar_';

  Future<PreferenciasApariencia> read() async {
    return PreferenciasApariencia(
      tema: _leerEnum<TemaApp>('tema', TemaApp.values, TemaApp.sistema),
      tamanoTexto: _leerEnum<TamanoTexto>(
        'tamano',
        TamanoTexto.values,
        TamanoTexto.normal,
      ),
      contraste: _leerEnum<Contraste>(
        'contraste',
        Contraste.values,
        Contraste.normal,
      ),
      reducirAnimaciones: _leerBool('animaciones', porDefecto: false),
      modoDaltonismo: _leerEnum<ModoDaltonismo>(
        'daltonismo',
        ModoDaltonismo.values,
        ModoDaltonismo.normal,
      ),
    );
  }

  Future<void> save(PreferenciasApariencia prefs) async {
    await _preferences.setString('${_prefijo}tema', prefs.tema.name);
    await _preferences.setString('${_prefijo}tamano', prefs.tamanoTexto.name);
    await _preferences.setString('${_prefijo}contraste', prefs.contraste.name);
    await _preferences.setBool(
      '${_prefijo}animaciones',
      prefs.reducirAnimaciones,
    );
    await _preferences.setString(
      '${_prefijo}daltonismo',
      prefs.modoDaltonismo.name,
    );
  }

  /// Borra solo las claves de apariencia: el historial de búsqueda y las
  /// preferencias de notificación viven en las mismas [SharedPreferences].
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

  /// Busca el valor guardado entre las opciones del catálogo. Un tipo
  /// equivocado o un nombre que ya no existe devuelve [porDefecto].
  T _leerEnum<T extends Enum>(String clave, List<T> opciones, T porDefecto) {
    String? guardado;
    try {
      guardado = _preferences.getString('$_prefijo$clave');
    } on Object {
      return porDefecto;
    }
    if (guardado == null) return porDefecto;
    for (final opcion in opciones) {
      if (opcion.name == guardado) return opcion;
    }
    return porDefecto;
  }
}
