import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardián de la configuración del proveedor de mapas (07.5 §7).
///
/// La app usa OpenStreetMap vía `flutter_map`: no hay API key, ni meta-data
/// de Google en el manifiesto, ni fallo de build por credenciales. Si alguien
/// reintrodujera `google_maps_flutter`, estos tests lo delatan.
void main() {
  group('configuración de mapas', () {
    test('el manifiesto no exige la API key de Google Maps', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();

      expect(manifest, isNot(contains('com.google.android.geo.API_KEY')));
      expect(manifest, isNot(contains('MAPS_API_KEY')));
    });

    test('Gradle no resuelve ni inyecta una API key de mapas', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, isNot(contains('mapsApiKey')));
      expect(gradle, isNot(contains('MAPS_API_KEY')));
    });

    test('las dependencias son de OpenStreetMap, no de Google', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('flutter_map:'));
      expect(pubspec, contains('latlong2:'));
      expect(pubspec, isNot(contains('google_maps_flutter')));
    });
  });
}
