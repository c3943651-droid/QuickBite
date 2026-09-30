import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/widgets/map_styles.dart';

/// Widget reutilizable que muestra un Google Map con:
/// - Marcadores de [origin] y [destination].
/// - Polilínea de ruta en color teal (`AppColors.accent`).
/// - Estilo de mapa adaptado automáticamente al modo claro/oscuro del sistema
///   (o forzado por [isDarkMode]).
///
/// ## Ejemplo de uso
/// ```dart
/// DeliveryMap(
///   origin: const LatLng(13.6929, -89.2182),
///   destination: const LatLng(13.7000, -89.2100),
///   routePolyline: myRoutePoints,
///   originTitle: 'Restaurante QuickBite',
///   destinationTitle: 'Cliente',
/// )
/// ```
class DeliveryMap extends StatefulWidget {
  const DeliveryMap({
    super.key,
    required this.origin,
    required this.destination,
    required this.routePolyline,
    this.originTitle,
    this.destinationTitle,
    this.onMapCreated,
    this.isDarkMode,
  });

  /// Coordenadas de origen (ej. posición actual del repartidor / restaurante).
  final LatLng origin;

  /// Coordenadas de destino (ej. dirección del cliente).
  final LatLng destination;

  /// Lista de puntos que forman la polilínea de la ruta.
  /// Si está vacía, no se dibuja ninguna polilínea.
  final List<LatLng> routePolyline;

  /// Título del marcador de origen. Si es null no muestra InfoWindow.
  final String? originTitle;

  /// Título del marcador de destino. Si es null no muestra InfoWindow.
  final String? destinationTitle;

  /// Callback invocado cuando el mapa termina de inicializarse.
  final void Function(GoogleMapController)? onMapCreated;

  /// Fuerza un tema concreto. Si es `null`, se detecta automáticamente
  /// desde `Theme.of(context).brightness`.
  final bool? isDarkMode;

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  // -------------------------------------------------------------------------
  // Cycle
  // -------------------------------------------------------------------------

  @override
  void didUpdateWidget(DeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reaplica el estilo si cambia el modo oscuro
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _applyMapStyle();
    }
  }

  // -------------------------------------------------------------------------
  // Callbacks
  // -------------------------------------------------------------------------

  Future<void> _onMapCreated(GoogleMapController controller) async {
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
    await _applyMapStyle();
    widget.onMapCreated?.call(controller);
  }

  Future<void> _applyMapStyle() async {
    final controller = await _controllerCompleter.future;
    final isDark = widget.isDarkMode ??
        (Theme.of(context).brightness == Brightness.dark);
    await controller.setMapStyle(isDark ? MapStyles.dark : MapStyles.light);
  }

  // -------------------------------------------------------------------------
  // Builders
  // -------------------------------------------------------------------------

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.origin,
        infoWindow: widget.originTitle != null
            ? InfoWindow(title: widget.originTitle)
            : InfoWindow.noText,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: widget.destinationTitle != null
            ? InfoWindow(title: widget.destinationTitle)
            : InfoWindow.noText,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (widget.routePolyline.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routePolyline,
        color: AppColors.accent,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  CameraPosition _initialCamera() {
    // Centra entre origen y destino
    final centerLat = (widget.origin.latitude + widget.destination.latitude) / 2;
    final centerLng = (widget.origin.longitude + widget.destination.longitude) / 2;
    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 13,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: _initialCamera(),
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}
