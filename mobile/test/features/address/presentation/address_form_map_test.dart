import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickbite_mobile/src/features/address/data/reverse_geocoding_service.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_form_screen.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_providers.dart';
import 'package:quickbite_mobile/src/features/address/presentation/select_location_map_screen.dart';
import 'package:quickbite_mobile/src/features/delivery/data/location_permission_service.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';

import 'addresses_screens_test.dart';

class _FakeGeocoder implements ReverseGeocodingService {
  SugerenciaDireccion? sugerencia;

  @override
  Future<SugerenciaDireccion?> desdeCoordenadas(
    double latitud,
    double longitud,
  ) async => sugerencia;
}

class _FakePermisos implements LocationPermissionService {
  @override
  Future<LocationPermissionStatus> checkStatus() async =>
      LocationPermissionStatus.whenInUse;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.whenInUse;
}

void main() {
  late ProviderContainer container;
  late _FakeGeocoder geocoder;

  setUp(() {
    geocoder = _FakeGeocoder();
    container = ProviderContainer(
      overrides: [
        addressRepositoryProvider.overrideWithValue(FakeAddressRepository()),
        mapViewBuilderProvider.overrideWithValue(
          (state, controller) => const SizedBox(key: Key('mapa-falso')),
        ),
        reverseGeocodingServiceProvider.overrideWithValue(geocoder),
        locationPermissionServiceProvider.overrideWithValue(_FakePermisos()),
        currentPositionLoaderProvider.overrideWithValue(
          () async => const LatLng(13.75, -89.15),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> abrirFormulario(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AddressFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> llenar(WidgetTester tester, String label, String value) =>
      tester.enterText(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(TextFormField),
        ),
        value,
      );

  String valorDe(WidgetTester tester, String label) {
    final campo = tester.widget<TextFormField>(
      find.ancestor(of: find.text(label), matching: find.byType(TextFormField)),
    );
    return campo.controller?.text ?? '';
  }

  Future<void> confirmarEnElMapa(WidgetTester tester, LatLng destino) async {
    final controlador = container.read(
      locationMapControllerProvider(null).notifier,
    );
    controlador.moverCamara(destino);
    await controlador.resolverSugerencia();
    await tester.pump();

    await tester.tap(find.text('Usar esta ubicación'));
    await tester.pumpAndSettle();
  }

  testWidgets('el botón "Ubicar en el mapa" abre el selector', (tester) async {
    await abrirFormulario(tester);

    await tester.tap(find.text('Ubicar en el mapa'));
    await tester.pumpAndSettle();

    expect(find.text('Usar esta ubicación'), findsOneWidget);
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
  });

  testWidgets('al volver del mapa se actualizan latitud y longitud', (
    tester,
  ) async {
    await abrirFormulario(tester);

    await tester.tap(find.text('Ubicar en el mapa'));
    await tester.pumpAndSettle();
    await confirmarEnElMapa(tester, const LatLng(13.8, -89.1));

    expect(valorDe(tester, 'Latitud'), '13.8');
    expect(valorDe(tester, 'Longitud'), '-89.1');
  });

  testWidgets('la sugerencia rellena calle y ciudad sin tocar número', (
    tester,
  ) async {
    geocoder.sugerencia = const SugerenciaDireccion(
      calle: 'Av. Principal',
      ciudad: 'San Salvador',
    );
    await abrirFormulario(tester);

    await llenar(tester, 'Número', '123');
    await llenar(tester, 'Referencia', 'Portón azul');
    await llenar(tester, 'Calle', 'Calle Vieja');
    await llenar(tester, 'Ciudad', 'Ciudad Vieja');

    await tester.tap(find.text('Ubicar en el mapa'));
    await tester.pumpAndSettle();
    await confirmarEnElMapa(tester, const LatLng(13.8, -89.1));

    expect(valorDe(tester, 'Calle'), 'Av. Principal');
    expect(valorDe(tester, 'Ciudad'), 'San Salvador');
    expect(valorDe(tester, 'Número'), '123');
    expect(valorDe(tester, 'Referencia'), 'Portón azul');
  });

  testWidgets('sin sugerencia se conservan calle y ciudad escritas', (
    tester,
  ) async {
    await abrirFormulario(tester);

    await llenar(tester, 'Calle', 'Calle Manual');
    await llenar(tester, 'Ciudad', 'Ciudad Manual');

    await tester.tap(find.text('Ubicar en el mapa'));
    await tester.pumpAndSettle();
    await confirmarEnElMapa(tester, const LatLng(13.8, -89.1));

    expect(valorDe(tester, 'Calle'), 'Calle Manual');
    expect(valorDe(tester, 'Ciudad'), 'Ciudad Manual');
    expect(valorDe(tester, 'Latitud'), '13.8');
  });

  testWidgets('los campos siguen editables tras volver del mapa', (
    tester,
  ) async {
    await abrirFormulario(tester);

    await tester.tap(find.text('Ubicar en el mapa'));
    await tester.pumpAndSettle();
    await confirmarEnElMapa(tester, const LatLng(13.8, -89.1));

    await llenar(tester, 'Latitud', '14.0');
    expect(valorDe(tester, 'Latitud'), '14.0');
  });
}
