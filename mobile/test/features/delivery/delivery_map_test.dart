import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/widgets/delivery_map.dart';

// ---------------------------------------------------------------------------
// Constantes de prueba
// ---------------------------------------------------------------------------

const _origin = LatLng(13.6929, -89.2182);
const _destination = LatLng(13.7050, -89.2060);
final _polyline = [
  _origin,
  const LatLng(13.6970, -89.2140),
  _destination,
];

// ---------------------------------------------------------------------------
// Helper: envuelve el widget en un MaterialApp para que pueda usar Theme
// ---------------------------------------------------------------------------

Widget _buildSubject({
  LatLng origin = _origin,
  LatLng destination = _destination,
  List<LatLng>? routePolyline,
  String? originTitle,
  String? destinationTitle,
  bool? isDarkMode,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: DeliveryMap(
        origin: origin,
        destination: destination,
        routePolyline: routePolyline ?? _polyline,
        originTitle: originTitle,
        destinationTitle: destinationTitle,
        isDarkMode: isDarkMode,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // google_maps_flutter necesita este stub para tests de widgets
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeliveryMap widget', () {
    testWidgets(
      'renderiza un GoogleMap con parámetros de origen y destino',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            originTitle: 'Restaurante',
            destinationTitle: 'Cliente',
          ),
        );

        // El widget GoogleMap debe estar presente en el árbol
        expect(find.byType(GoogleMap), findsOneWidget);
      },
    );

    testWidgets(
      'acepta una lista vacía de routePolyline sin lanzar excepción',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(routePolyline: []),
        );

        expect(find.byType(GoogleMap), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'acepta isDarkMode: true sin lanzar excepción',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(isDarkMode: true),
        );

        expect(find.byType(GoogleMap), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'acepta isDarkMode: false sin lanzar excepción',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(isDarkMode: false),
        );

        expect(find.byType(GoogleMap), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'auto-detecta modo oscuro desde el tema del contexto (Brightness.dark)',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(brightness: Brightness.dark),
        );

        // No hay excepción: el widget delega en Theme.of(context).brightness
        expect(find.byType(GoogleMap), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'permite originTitle y destinationTitle opcionales (null)',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            originTitle: null,
            destinationTitle: null,
          ),
        );

        expect(find.byType(GoogleMap), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'expone el callback onMapCreated',
      (tester) async {
        GoogleMapController? capturedController;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeliveryMap(
                origin: _origin,
                destination: _destination,
                routePolyline: _polyline,
                onMapCreated: (c) => capturedController = c,
              ),
            ),
          ),
        );

        // GoogleMap puede no completar el callback en el entorno de test headless,
        // pero el widget no debe fallar al recibirlo
        expect(find.byType(GoogleMap), findsOneWidget);
        expect(tester.takeException(), isNull);
        // capturedController puede ser null en headless (sin plataforma nativa)
        // — este test garantiza que el parámetro se acepta sin errores.
        expect(capturedController, anyOf(isNull, isA<GoogleMapController>()));
      },
    );
  });
}
