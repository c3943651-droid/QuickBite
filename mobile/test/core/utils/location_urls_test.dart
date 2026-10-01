import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/utils/location_urls.dart';

void main() {
  group('googleMapsUri', () {
    test('construye la URL de búsqueda de Google Maps', () {
      expect(
        googleMapsUri(13.7, -89.2).toString(),
        'https://www.google.com/maps/search/?api=1&query=13.7,-89.2',
      );
    });

    test('conserva la precisión de coordenadas negativas', () {
      expect(
        googleMapsUri(-13.6929, -89.2182).toString(),
        'https://www.google.com/maps/search/?api=1&query=-13.6929,-89.2182',
      );
    });
  });

  group('wazeUri', () {
    test('construye la URL de ubicación de Waze', () {
      expect(
        wazeUri(13.7, -89.2).toString(),
        'https://waze.com/ul?ll=13.7,-89.2',
      );
    });

    test('acepta coordenadas negativas', () {
      expect(
        wazeUri(-13.6929, -89.2182).toString(),
        'https://waze.com/ul?ll=-13.6929,-89.2182',
      );
    });
  });
}
