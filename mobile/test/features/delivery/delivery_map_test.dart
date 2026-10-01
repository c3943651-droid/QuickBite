import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/widgets/delivery_map.dart';

// ---------------------------------------------------------------------------
// Constantes de prueba
// ---------------------------------------------------------------------------

const _origin = LatLng(13.6929, -89.2182);
const _destination = LatLng(13.7050, -89.2060);
final _polyline = [_origin, const LatLng(13.6970, -89.2140), _destination];

// ---------------------------------------------------------------------------
// Helper: envuelve el widget en un MaterialApp para que pueda usar Theme
// ---------------------------------------------------------------------------

Widget _buildSubject({
  LatLng origin = _origin,
  LatLng destination = _destination,
  List<LatLng>? routePolyline,
  String? originTitle,
  String? destinationTitle,
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
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeliveryMap widget', () {
    testWidgets('renderiza un FlutterMap con parámetros de origen y destino', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(originTitle: 'Restaurante', destinationTitle: 'Cliente'),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
    });

    testWidgets(
      'acepta una lista vacía de routePolyline sin lanzar excepción',
      (tester) async {
        await tester.pumpWidget(_buildSubject(routePolyline: []));

        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.byType(PolylineLayer), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('se renderiza en un tema oscuro sin lanzar excepción', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(brightness: Brightness.dark));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('permite originTitle y destinationTitle opcionales (null)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(originTitle: null, destinationTitle: null),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expone el callback onMapCreated con un MapController ligado', (
      tester,
    ) async {
      MapController? capturedController;

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
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(capturedController, isA<MapController>());
    });
  });
}
