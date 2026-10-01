import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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

/// Geocoder que incumple el contrato y lanza (fallo de proveedor nativo).
class _GeocoderFalla implements ReverseGeocodingService {
  @override
  Future<SugerenciaDireccion?> desdeCoordenadas(
    double latitud,
    double longitud,
  ) async => throw Exception('sin red');
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

  ProviderContainer crearContainer(
    ReverseGeocodingService geocoding, {
    bool mapaReal = false,
  }) {
    final overrides = [
      reverseGeocodingServiceProvider.overrideWithValue(geocoding),
      locationPermissionServiceProvider.overrideWithValue(permisos),
      currentPositionLoaderProvider.overrideWithValue(() async {
        final posicion = posicionGps;
        if (posicion == null) {
          throw Exception('sin posicion de prueba');
        }
        return posicion;
      }),
    ];
    if (!mapaReal) {
      overrides.add(
        mapViewBuilderProvider.overrideWithValue(
          (state, controller) => const SizedBox(key: Key('mapa-falso')),
        ),
      );
    }
    final creado = ProviderContainer(overrides: overrides);
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

  testWidgets('un movimiento de cámara no deja el indicador de carga colgado', (
    tester,
  ) async {
    final lento = _GeocoderLento();
    container = crearContainer(lento);
    await abrirSelector(tester);

    final controlador = container.read(
      locationMapControllerProvider(null).notifier,
    );
    final enVuelo = controlador.resolverSugerencia();
    await tester.pump();
    expect(leerEstado().cargandoSugerencia, isTrue);

    controlador.moverCamara(const LatLng(13.9, -89.3));
    await tester.pump();
    expect(leerEstado().cargandoSugerencia, isFalse);

    controlador.resolverSugerencia();
    await tester.pump();
    expect(leerEstado().cargandoSugerencia, isTrue);
    controlador.moverCamara(leerEstado().centro);
    await tester.pump();
    expect(leerEstado().cargandoSugerencia, isFalse);

    for (final espera in lento.esperas) {
      if (!espera.isCompleted) {
        espera.complete(const SugerenciaDireccion(calle: 'Obsoleta'));
      }
    }
    await enVuelo;
    await tester.pump();
    expect(leerEstado().cargandoSugerencia, isFalse);
    expect(leerEstado().sugerencia, isNull);
  });

  testWidgets('si el geocoder lanza, el indicador de carga se apaga', (
    tester,
  ) async {
    container = crearContainer(_GeocoderFalla());
    await abrirSelector(tester);

    await container
        .read(locationMapControllerProvider(null).notifier)
        .resolverSugerencia();
    await tester.pump();

    expect(leerEstado().cargandoSugerencia, isFalse);
    expect(leerEstado().error, isNull);
  });

  testWidgets(
    'arrastrar el mapa real actualiza el centro y geocodifica tras el debounce',
    (tester) async {
      final lento = _GeocoderLento();
      container = crearContainer(lento, mapaReal: true);
      await abrirSelector(tester);

      expect(find.byType(FlutterMap), findsOneWidget);

      await tester.drag(find.byType(FlutterMap), const Offset(-160, 0));
      await tester.pump();

      expect(leerEstado().centro, isNot(ubicacionQuickBite));

      // El debounce (400 ms) dispara la geocodificación tras el último
      // movimiento (arrastra + fling). Se avanza el reloj hasta que ocurra.
      var intentos = 0;
      while (lento.esperas.isEmpty && intentos < 60) {
        await tester.pump(const Duration(milliseconds: 100));
        intentos++;
      }
      expect(lento.esperas, isNotEmpty);

      for (final espera in lento.esperas) {
        if (!espera.isCompleted) {
          espera.complete(const SugerenciaDireccion(calle: 'Calle Arrastrada'));
        }
      }
      await tester.pump();

      expect(leerEstado().cargandoSugerencia, isFalse);
      expect(leerEstado().sugerencia?.calle, 'Calle Arrastrada');
    },
  );

  testWidgets(
    'tocar el mapa mueve el pin a ese punto y geocodifica tras el debounce',
    (tester) async {
      final lento = _GeocoderLento();
      container = crearContainer(lento, mapaReal: true);
      await abrirSelector(tester);

      final centro = tester.getCenter(find.byType(FlutterMap));
      // Toque al oeste del centro: el pin debe saltar a ese punto, así que el
      // centro del mapa pasa a quedar más al oeste.
      await tester.tapAt(Offset(centro.dx - 150, centro.dy));
      // flutter_map confirma el toque simple tras su ventana de doble toque
      // (250 ms), para poder distinguir un zoom por doble toque.
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        leerEstado().centro.longitude,
        lessThan(ubicacionQuickBite.longitude),
      );

      // Mismo flujo que el arrastre: debounce y luego geocodificación.
      var intentos = 0;
      while (lento.esperas.isEmpty && intentos < 60) {
        await tester.pump(const Duration(milliseconds: 100));
        intentos++;
      }
      expect(lento.esperas, isNotEmpty);

      for (final espera in lento.esperas) {
        if (!espera.isCompleted) {
          espera.complete(const SugerenciaDireccion(calle: 'Calle Tocada'));
        }
      }
      await tester.pump();

      expect(leerEstado().cargandoSugerencia, isFalse);
      expect(leerEstado().sugerencia?.calle, 'Calle Tocada');
    },
  );

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
