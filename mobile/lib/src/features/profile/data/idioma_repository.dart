import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preferencias_idioma.dart';

/// Persistencia local de idioma y formatos regionales (07.1 SCR-PROF-10).
///
/// Solo guarda los dos formatos: el idioma no se persiste porque en v1.0 tiene
/// una única opción y guardarla sugeriría que se puede cambiar. Cuando haya
/// más, la clave `quickbite_idioma_app` queda reservada y se lee en [read].
class IdiomaRepository {
  const IdiomaRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _idioma = 'quickbite_idioma_app';
  static const _fecha = 'quickbite_idioma_fecha';
  static const _hora = 'quickbite_idioma_hora';

  Future<PreferenciasIdioma> read() async {
    return PreferenciasIdioma(
      idioma: _leerEnum(_idioma, IdiomaApp.values),
      formatoFecha: _leerEnum(_fecha, FormatoFecha.values),
      formatoHora: _leerEnum(_hora, FormatoHora.values),
    );
  }

  Future<void> save(PreferenciasIdioma prefs) async {
    await _preferences.setString(_fecha, prefs.formatoFecha.name);
    await _preferences.setString(_hora, prefs.formatoHora.name);
  }

  Future<void> clear() async {
    await _preferences.remove(_fecha);
    await _preferences.remove(_hora);
  }

  /// Devuelve la opción guardada si sigue existiendo en el catálogo y, si no, la
  /// primera del enum, que es siempre el valor por defecto de la app. Un solo
  /// mecanismo cubre así "nada guardado", "otro tipo" y "nombre desconocido".
  T _leerEnum<T extends Enum>(String clave, List<T> opciones) {
    String? guardado;
    try {
      guardado = _preferences.getString(clave);
    } on Object {
      return opciones.first;
    }
    if (guardado == null) return opciones.first;
    for (final opcion in opciones) {
      if (opcion.name == guardado) return opcion;
    }
    return opciones.first;
  }
}
