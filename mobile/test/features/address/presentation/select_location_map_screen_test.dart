import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickbite_mobile/src/features/address/data/reverse_geocoding_service.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_providers.dart';
import 'package:quickbite_mobile/src/features/address/presentation/select_location_map_screen.dart';
import 'package:quickbite_mobile/src/features/delivery/data/location_permission_service.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';

class _FakeGeocoder implements ReverseGeocodingService {
  SugerenciaDireccion? sugerencia;

  @override
  Future<SugerenciaDireccion?> desdeCoordenadas(
    double latitud,
    double longitud,
  ) async => sugerencia;
}

/// Geocoder controlado a mano: cada llamada queda en vuelo hasta que el test
/// la completa, para verificar el descarte de respuestas obsoletas.
class _GeocoderLento implements ReverseGeocodingService {
  final List<Completer<SugerenciaDireccion?>> esperas = [];

  @override
  Future<SugerenciaDireccion?> desdeCoordenadas(
    double latitud,
    double longitud,
  ) {
    final espera = Completer<SugerenciaDireccion?>();
    esperas.add(espera);
    return espera.future;
  }
}

class _FakePermisos implements LocationPermissionService {
  _FakePermisos(this.respuesta);

  LocationPermissionStatus respuesta;

  @override
  Future<LocationPermissionStatus> checkStatus() async => respuesta;

  @override
  Future<LocationPermissionStatus> requestPermission() async => respuesta;
}

void main() {
  Future<SeleccionUbicacion?>? resultado;
  late ProviderContainer container;
  late _FakeGeocoder geocoder;
  late _FakePermisos permisos;
  LatLng? posicionGps;

  ProviderContainer crearContainer(ReverseGeocodingService geocoding) {
    final creado = ProviderContainer(
      overrides: [
        mapViewBuilderProvider.overrideWithValue(
          (state, controller) => const SizedBox(key: Key('mapa-falso')),
        ),
        reverseGeocodingServiceProvider.overrideWithValue(geocoding),
        locationPermissionServiceProvider.overrideWithValue(permisos),
        currentPositionLoaderProvider.overrideWithValue(() async {
          final posicion = posicionGps;
          if (posicion == null) {
            throw Exception('sin posicion de prueba');
          }
          return posicion;
        }),
      ],
    );
    addTearDown(creado.dispose);
    return creado;
  }

  setUp(() {
    resultado = null;
    geocoder = _FakeGeocoder();
    permisos = _FakePermisos(LocationPermissionStatus.whenInUse);
    posicionGps = null;
    container = crearContainer(geocoder);
  });

  Future<void> abrirSelector(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  key: const Key('abrir-selector'),
                  onPressed: () {
                    resultado = SelectLocationMapScreen.mostrar(context);
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir-selector')));
    await tester.pumpAndSettle();
  }

  LocationMapState leerEstado() =>
      container.read(locationMapControllerProvider(null));

  testWidgets('abre la pantalla con el mapa, el pin y el botón de confirmar', (
    tester,
  ) async {
    await abrirSelector(tester);

    expect(find.text('Ubicar en el mapa'), findsOneWidget);
    expect(find.byKey(const Key('mapa-falso')), findsOneWidget);
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
    expect(find.text('Usar esta ubicación'), findsOneWidget);
    expect(
      find.text('Arrastra el mapa hasta colocar el pin sobre tu puerta'),
      findsOneWidget,
    );
  });

  testWidgets('confirma y devuelve la posición centrada tras mover el mapa', (
    tester,
  ) async {
    await abrirSelector(tester);

    container
        .read(locationMapControllerProvider(null).notifier)
        .moverCamara(const LatLng(13.8, -89.1));
    await tester.pump();

    await tester.tap(find.text('Usar esta ubicación'));
    await tester.pumpAndSettle();

    final elegida = (await resultado!)!;
    expect(elegida.ubicacion, const LatLng(13.8, -89.1));
  });

  testWidgets(
    'muestra la sugerencia del geocoder y la incluye en el resultado',
    (tester) async {
      geocoder.sugerencia = const SugerenciaDireccion(
        calle: 'Av. Principal',
        ciudad: 'San Salvador',
      );
      await abrirSelector(tester);

      await container
          .read(locationMapControllerProvider(null).notifier)
          .resolverSugerencia();
      await tester.pump();

      expect(find.text('Av. Principal'), findsOneWidget);
      expect(find.text('San Salvador'), findsOneWidget);

      await tester.tap(find.text('Usar esta ubicación'));
      await tester.pumpAndSettle();

      final elegida = (await resultado!)!;
      expect(elegida.sugerencia?.calle, 'Av. Principal');
      expect(elegida.sugerencia?.ciudad, 'San Salvador');
    },
  );

  testWidgets('descarta la respuesta obsoleta si la cámara se vuelve a mover', (
    tester,
  ) async {
    final lento = _GeocoderLento();
    container = crearContainer(lento);
    await abrirSelector(tester);

    final controlador = container.read(
      locationMapControllerProvider(null).notifier,
    );
    final primera = controlador.resolverSugerencia();
    controlador.moverCamara(const LatLng(13.9, -89.3));
    final segunda = controlador.resolverSugerencia();
    await tester.pump();

    expect(lento.esperas, hasLength(2));
    lento.esperas[1].complete(const SugerenciaDireccion(calle: 'Calle Nueva'));
    await segunda;
    await tester.pump();
    expect(leerEstado().sugerencia?.calle, 'Calle Nueva');

    lento.esperas[0].complete(const SugerenciaDireccion(calle: 'Calle Vieja'));
    await primera;
    await tester.pump();
    expect(leerEstado().sugerencia?.calle, 'Calle Nueva');
  });

  testWidgets('el botón GPS centra el mapa en la posición del dispositivo', (
    tester,
  ) async {
    geocoder.sugerencia = const SugerenciaDireccion(calle: 'Desde GPS');
    posicionGps = const LatLng(13.75, -89.15);
    await abrirSelector(tester);

    await tester.tap(find.byTooltip('Mi ubicación'));
    await tester.pumpAndSettle();

    expect(leerEstado().centro, const LatLng(13.75, -89.15));
    expect(leerEstado().vueloPendiente, isTrue);
    expect(find.text('Desde GPS'), findsOneWidget);
  });

  testWidgets('sin permiso de ubicación muestra el error en la tarjeta', (
    tester,
  ) async {
    permisos.respuesta = LocationPermissionStatus.deniedForever;
    await abrirSelector(tester);

    await tester.tap(find.byTooltip('Mi ubicación'));
    await tester.pumpAndSettle();

    expect(
      find.text('Activa los permisos de ubicación para usar tu posición.'),
      findsOneWidget,
    );
    expect(leerEstado().centro, ubicacionQuickBite);
  });
}
