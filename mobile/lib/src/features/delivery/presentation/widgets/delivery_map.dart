import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:quickbite_mobile/src/core/theme/app_colors.dart';

/// Widget reutilizable que muestra un mapa OpenStreetMap con:
/// - Marcadores de [origin] y [destination] (con rótulo opcional).
/// - Polilínea de ruta en color teal (`AppColors.accent`).
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
    this.riderLocation,
  });

  /// Coordenadas de origen (ej. posición actual del repartidor / restaurante).
  final LatLng origin;

  /// Coordenadas de destino (ej. dirección del cliente).
  final LatLng destination;

  /// Lista de puntos que forman la polilínea de la ruta.
  /// Si está vacía, no se dibuja ninguna polilínea.
  final List<LatLng> routePolyline;

  /// Rótulo opcional del marcador de origen.
  final String? originTitle;

  /// Rótulo opcional del marcador de destino.
  final String? destinationTitle;

  /// Callback invocado tras el primer frame, cuando el [MapController] ya
  /// está ligado al mapa.
  final void Function(MapController)? onMapCreated;

  /// Posición actual del repartidor. `null` cuando no hay GPS o no se pidió
  /// permiso: el mapa se dibuja igual, solo que sin su marcador.
  final LatLng? riderLocation;

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  late final MapController _mapa;

  /// Posición del repartidor o `null` si todavía no se conoce.
  LatLng? get posicion => widget.riderLocation;

  @override
  void initState() {
    super.initState();
    _mapa = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onMapCreated?.call(_mapa);
      }
    });
  }

  List<Marker> _marcadores() {
    // El repartidor va el último para que su marcador quede por encima: es el
    // que tiene que verse moverse sobre su propia ruta.
    final propia = posicion;
    return [
      _marcador(widget.origin, widget.originTitle, const Color(0xFF03A9F4)),
      _marcador(
        widget.destination,
        widget.destinationTitle,
        const Color(0xFF00BCD4),
      ),
      if (propia != null)
        Marker(
          point: propia,
          width: 28,
          height: 28,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delivery_dining,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Marker _marcador(LatLng punto, String? titulo, Color color) => Marker(
    point: punto,
    width: 110,
    height: 64,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, size: 40, color: color),
        if (titulo != null)
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black,
              backgroundColor: Colors.white70,
            ),
          ),
      ],
    ),
  );

  Polyline? _ruta() => widget.routePolyline.isEmpty
      ? null
      : Polyline(
          points: widget.routePolyline,
          strokeWidth: 4,
          color: AppColors.accent,
        );

  @override
  Widget build(BuildContext context) {
    // Centra entre origen y destino.
    final centro = LatLng(
      (widget.origin.latitude + widget.destination.latitude) / 2,
      (widget.origin.longitude + widget.destination.longitude) / 2,
    );
    final ruta = _ruta();
    return FlutterMap(
      mapController: _mapa,
      options: MapOptions(initialCenter: centro, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.quickbite.quickbite_mobile',
          maxNativeZoom: 19,
        ),
        if (ruta != null) PolylineLayer(polylines: [ruta]),
        MarkerLayer(markers: _marcadores()),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('Colaboradores de OpenStreetMap'),
          ],
        ),
      ],
    );
  }
}
