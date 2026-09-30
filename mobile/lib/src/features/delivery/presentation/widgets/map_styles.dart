/// Estilos JSON para Google Maps alineados al Design System de QuickBite.
///
/// - **Modo claro**: estilo limpio, sin saturación extra, que deja los elementos
///   de la ruta (polilínea teal `#0D9488`) resaltar sobre el mapa.
/// - **Modo oscuro**: fondo `#0B1220` (`AppColors.nightBackground`), superficies
///   `#111C2E` (`AppColors.nightSurface`), etiquetas en pizarra clara.
///
/// Los JSON siguen el esquema de Google Maps Styling Wizard
/// (https://mapstyle.withgoogle.com). Cada entrada puede tener:
///   - `featureType`: categoría del elemento (road, water, poi…).
///   - `elementType`: geometría o etiqueta.
///   - `stylers`: lista de transformaciones (color, visibility, lightness…).
abstract final class MapStyles {
  // ---------------------------------------------------------------------------
  // Modo claro
  // ---------------------------------------------------------------------------

  /// Estilo de Google Maps para modo claro.
  /// Aplana el ruido visual (POIs, tránsito) para que la polilínea de ruta
  /// sea el único elemento llamativo en el mapa.
  static const String light = r'''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#f5f5f5" }]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#616161" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#f5f5f5" }]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#bdbdbd" }]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{ "color": "#eeeeee" }]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{ "color": "#e5f5e5" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{ "color": "#ffffff" }]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{ "color": "#dadada" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#616161" }]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#9e9e9e" }]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [{ "color": "#e5e5e5" }]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [{ "color": "#eeeeee" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#c9e5f5" }]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#9e9e9e" }]
  }
]
''';

  // ---------------------------------------------------------------------------
  // Modo oscuro
  // ---------------------------------------------------------------------------

  /// Estilo de Google Maps para modo oscuro.
  /// Fondo `#0B1220` (`AppColors.nightBackground`), superficies `#111C2E`
  /// (`AppColors.nightSurface`), calles en pizarra media y etiquetas claras.
  /// Los POIs de parques y agua usan tonos que contrastan sin saturar.
  static const String dark = r'''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#0b1220" }]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#8a9ab5" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#0b1220" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{ "color": "#111c2e" }]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#9aa3b0" }]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#c8d0db" }]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#6b7a90" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{ "color": "#0d2a1e" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#3a7d5c" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#1e293b" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#7a8a9e" }]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{ "color": "#1e3050" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{ "color": "#253655" }]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [{ "color": "#2c4070" }]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#475569" }]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#3a4f68" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#0a1828" }]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#3a5a7c" }]
  }
]
''';
}
