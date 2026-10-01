import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:quickbite_mobile/src/features/address/data/reverse_geocoding_service.dart';

void main() {
  group('sugerirDesde', () {
    test('mapea thoroughfare a calle y locality a ciudad', () {
      const placemark = Placemark(
        thoroughfare: 'Av. Principal',
        locality: 'San Salvador',
      );

      final sugerencia = sugerirDesde(placemark);

      expect(sugerencia, isNotNull);
      expect(sugerencia!.calle, 'Av. Principal');
      expect(sugerencia.ciudad, 'San Salvador');
    });

    test('usa street como alternativa de calle', () {
      const placemark = Placemark(street: 'Calle 5', locality: 'Santa Ana');

      final sugerencia = sugerirDesde(placemark);

      expect(sugerencia!.calle, 'Calle 5');
      expect(sugerencia.ciudad, 'Santa Ana');
    });

    test('usa subAdministrativeArea si locality viene vacío', () {
      const placemark = Placemark(
        thoroughfare: 'Blvd. Los Próceres',
        subAdministrativeArea: 'San Salvador',
      );

      final sugerencia = sugerirDesde(placemark);

      expect(sugerencia!.ciudad, 'San Salvador');
    });

    test('devuelve null cuando no hay ningún dato aprovechable', () {
      expect(sugerirDesde(const Placemark()), isNull);
      expect(sugerirDesde(const Placemark(name: '   ')), isNull);
    });
  });

  group('ReverseGeocodingService', () {
    test('devuelve la sugerencia a partir de coordenadas', () async {
      final service = ReverseGeocodingService(
        lookup: (lat, lng) async => const [
          Placemark(thoroughfare: 'Av. Insurgentes', locality: 'CDMX'),
        ],
      );

      final sugerencia = await service.desdeCoordenadas(13.7, -89.2);

      expect(sugerencia!.calle, 'Av. Insurgentes');
      expect(sugerencia.ciudad, 'CDMX');
    });

    test('devuelve null si el geocoder no encuentra nada', () async {
      final service = ReverseGeocodingService(lookup: (lat, lng) async => []);

      expect(await service.desdeCoordenadas(13.7, -89.2), isNull);
    });

    test(
      'devuelve null si el geocoder falla, sin propagar la excepción',
      () async {
        final service = ReverseGeocodingService(
          lookup: (lat, lng) async => throw Exception('sin red'),
        );

        expect(await service.desdeCoordenadas(13.7, -89.2), isNull);
      },
    );
  });
}
