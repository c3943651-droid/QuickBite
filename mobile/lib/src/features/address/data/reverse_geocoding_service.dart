import 'package:geocoding/geocoding.dart';

/// Sugerencia de dirección obtenida por geocodificación inversa (07.5 §3.7).
/// Autocompleta calle, número y ciudad del formulario; alias y referencia
/// siguen siendo edición manual del usuario.
class SugerenciaDireccion {
  const SugerenciaDireccion({this.calle, this.numero, this.ciudad});

  final String? calle;

  /// Número de la puerta cuando el geocoder lo conoce. `null` si la vía no
  /// tiene número asociado o el geocoder no lo devuelve.
  final String? numero;

  final String? ciudad;
}

typedef PlacemarkLookup = Future<List<Placemark>> Function(
  double latitud,
  double longitud,
);

/// Traduce un [Placemark] del sistema a la sugerencia del formulario.
/// Devuelve `null` si no hay ningún dato aprovechable.
SugerenciaDireccion? sugerirDesde(Placemark placemark) {
  final calle =
      _noVacio(placemark.thoroughfare) ??
      _noVacio(placemark.street) ??
      _noVacio(placemark.name);
  final numero = _noVacio(placemark.subThoroughfare);
  final ciudad =
      _noVacio(placemark.locality) ??
      _noVacio(placemark.subAdministrativeArea) ??
      _noVacio(placemark.administrativeArea);
  if (calle == null && numero == null && ciudad == null) {
    return null;
  }
  return SugerenciaDireccion(calle: calle, numero: numero, ciudad: ciudad);
}

String? _noVacio(String? valor) {
  final texto = valor?.trim();
  return texto == null || texto.isEmpty ? null : texto;
}

/// Geocodificación inversa con el Geocoder nativo (paquete `geocoding`).
/// Cualquier fallo (sin red, sin servicio de geocoder) se traduce en `null`
/// para que el formulario nunca se bloquee (07.5 §6).
class ReverseGeocodingService {
  ReverseGeocodingService({PlacemarkLookup? lookup})
    : _lookup = lookup ?? _plataforma;

  final PlacemarkLookup _lookup;

  static Future<List<Placemark>> _plataforma(double latitud, double longitud) =>
      Geocoding().placemarkFromCoordinates(latitud, longitud);

  Future<SugerenciaDireccion?> desdeCoordenadas(
    double latitud,
    double longitud,
  ) async {
    try {
      final placemarks = await _lookup(latitud, longitud);
      if (placemarks.isEmpty) {
        return null;
      }
      return sugerirDesde(placemarks.first);
    } catch (_) {
      return null;
    }
  }
}
