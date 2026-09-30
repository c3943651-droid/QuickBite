import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un archivo exportado: el nombre con el que se guarda y su contenido.
class ArchivoExportado {
  const ArchivoExportado({required this.nombre, required this.contenido});

  final String nombre;
  final String contenido;
}

/// Mantenimiento local (07.1 SCR-PROF-14).
///
/// Solo toca lo que la app guarda en el dispositivo. No hay borrado remoto en
/// ninguna de estas acciones: los productos, pedidos y direcciones viven en el
/// servidor y se recargan solos, así que aquí no hay nada que borrar de ellos.
class MantenimientoRepository {
  const MantenimientoRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _historial = 'quickbite_search_history';
  static const _prefijosPreferencias = ['quickbite_prefs_', 'quickbite_apar_'];

  /// Deja las preferencias como de fábrica. No toca el historial, que tiene su
  /// propia fila en la pantalla para que el usuario decida por separado.
  Future<void> limpiarPreferencias() async {
    final propias = _preferences
        .getKeys()
        .where(
          (clave) =>
              clave != _historial &&
              _prefijosPreferencias.any(clave.startsWith),
        )
        .toList();
    for (final clave in propias) {
      await _preferences.remove(clave);
    }
  }

  /// Vacía el historial de búsquedas (05#D-13).
  Future<void> limpiarHistorialBusquedas() => _preferences.remove(_historial);

  /// Arma el JSON de una exportación.
  ///
  /// Se separa de [exportar] para poder comprobar el contenido sin tocar el
  /// sistema de archivos, que en un test no existe.
  static Future<ArchivoExportado> textoExportar({
    required String nombre,
    required Map<String, Object?> datos,
    DateTime? momento,
  }) async {
    final fecha = momento ?? DateTime.now();
    final contenido = jsonEncode({
      'app': 'QuickBite',
      'exportado_en': fecha.toIso8601String().substring(0, 10),
      ...datos,
    });

    return ArchivoExportado(
      nombre: 'quickbite-$nombre-${_sello(fecha)}.json',
      contenido: contenido,
    );
  }

  /// Escribe la exportación en el directorio de la app.
  ///
  /// [directorio] solo lo pasan los tests, para no escribir en el equipo de
  /// quien los corre.
  static Future<File> exportar({
    required String nombre,
    required Map<String, Object?> datos,
    Directory? directorio,
    DateTime? momento,
  }) async {
    final archivo = await textoExportar(
      nombre: nombre,
      datos: datos,
      momento: momento,
    );
    final destino = directorio ?? await getApplicationDocumentsDirectory();
    final ruta = File('${destino.path}/${archivo.nombre}');
    await ruta.writeAsString(archivo.contenido);
    return ruta;
  }

  static String _sello(DateTime momento) =>
      '${momento.year.toString().padLeft(4, '0')}-'
      '${momento.month.toString().padLeft(2, '0')}-'
      '${momento.day.toString().padLeft(2, '0')}';
}
