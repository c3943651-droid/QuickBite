import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../delivery/domain/models/location_permission_status.dart';
import '../../delivery/presentation/delivery_providers.dart';
import '../data/reverse_geocoding_service.dart';
import 'address_providers.dart';

/// Punto por defecto del selector: QuickBite Centro (07.5 §6), usado cuando la
/// dirección no tiene coordenadas guardadas.
const LatLng ubicacionQuickBite = LatLng(13.6929, -89.2182);

/// Resultado de [SelectLocationMapScreen.mostrar].
class SeleccionUbicacion {
  const SeleccionUbicacion({required this.ubicacion, this.sugerencia});

  final LatLng ubicacion;
  final SugerenciaDireccion? sugerencia;
}

typedef CurrentPositionLoader = Future<LatLng> Function();

/// Obtiene la posición GPS actual. Se inyecta para que los tests puedan
/// sustituirla sin GPS real.
final currentPositionLoaderProvider = Provider<CurrentPositionLoader>((ref) {
  return () async {
    final posicion = await Geolocator.getCurrentPosition();
    return LatLng(posicion.latitude, posicion.longitude);
  };
});

@immutable
class LocationMapState {
  const LocationMapState({
    required this.centro,
    this.cargandoSugerencia = false,
    this.sugerencia,
    this.error,
    this.vueloPendiente = false,
  });

  final LatLng centro;
  final bool cargandoSugerencia;
  final SugerenciaDireccion? sugerencia;
  final String? error;

  /// El mapa aún no ha volado hasta [centro] tras un cambio externo (GPS).
  final bool vueloPendiente;

  LocationMapState copyWith({
    LatLng? centro,
    bool? cargandoSugerencia,
    SugerenciaDireccion? sugerencia,
    bool limpiarSugerencia = false,
    String? error,
    bool limpiarError = false,
    bool? vueloPendiente,
  }) => LocationMapState(
    centro: centro ?? this.centro,
    cargandoSugerencia: cargandoSugerencia ?? this.cargandoSugerencia,
    sugerencia: sugerencia ?? (limpiarSugerencia ? null : this.sugerencia),
    error: error ?? (limpiarError ? null : this.error),
    vueloPendiente: vueloPendiente ?? this.vueloPendiente,
  );
}

/// Lógica de la pantalla de selección: centro del mapa, geocodificación con
/// descarte de respuestas obsoletas y localización GPS (07.5 §5, §6).
class LocationMapController extends Notifier<LocationMapState> {
  LocationMapController(this.inicial);

  final LatLng? inicial;
  int _peticion = 0;

  @override
  LocationMapState build() =>
      LocationMapState(centro: inicial ?? ubicacionQuickBite);

  /// La cámara se ha movido (arrastre del usuario o vuelo del GPS).
  void moverCamara(LatLng nueva) {
    // Invalida cualquier geocodificación en vuelo: su respuesta ya no aplica
    // a la nueva posición y, si nadie la recoge, el indicador se quedaría
    // animando para siempre (bucle de repaint).
    _peticion++;
    if (nueva == state.centro) {
      if (state.cargandoSugerencia) {
        state = state.copyWith(cargandoSugerencia: false);
      }
      return;
    }
    state = state.copyWith(
      centro: nueva,
      cargandoSugerencia: false,
      limpiarSugerencia: true,
      limpiarError: true,
    );
  }

  /// Geocodificación inversa para el centro actual. Solo la última petición
  /// en llegar actualiza el estado (la anterior queda obsoleta).
  Future<void> resolverSugerencia() async {
    final peticion = ++_peticion;
    final centro = state.centro;
    state = state.copyWith(cargandoSugerencia: true);
    SugerenciaDireccion? sugerencia;
    try {
      sugerencia = await ref
          .read(reverseGeocodingServiceProvider)
          .desdeCoordenadas(centro.latitude, centro.longitude);
    } catch (_) {
      sugerencia = null;
    } finally {
      // Solo la última petición apaga su propio indicador: si quedó
      // obsoleta, la que la sustituyó ya gestiona el suyo.
      if (peticion == _peticion) {
        state = state.copyWith(
          cargandoSugerencia: false,
          limpiarSugerencia: true,
          sugerencia: sugerencia,
        );
      }
    }
  }

  /// Centra el mapa en la posición GPS tras pedir permiso.
  Future<void> ubicarConGps() async {
    final permiso = await ref
        .read(locationPermissionServiceProvider)
        .requestPermission();
    if (permiso != LocationPermissionStatus.whenInUse &&
        permiso != LocationPermissionStatus.always) {
      state = state.copyWith(
        limpiarError: true,
        error: 'Activa los permisos de ubicación para usar tu posición.',
      );
      return;
    }
    try {
      final posicion = await ref.read(currentPositionLoaderProvider)();
      state = state.copyWith(
        centro: posicion,
        limpiarSugerencia: true,
        limpiarError: true,
        vueloPendiente: true,
      );
      await resolverSugerencia();
    } catch (_) {
      state = state.copyWith(
        limpiarError: true,
        error: 'No pudimos obtener tu ubicación.',
      );
    }
  }

  void consumirVuelo() => state = state.copyWith(vueloPendiente: false);
}

final locationMapControllerProvider = NotifierProvider.autoDispose
    .family<LocationMapController, LocationMapState, LatLng?>(
      LocationMapController.new,
    );

typedef MapaSeleccionBuilder = Widget Function(
  LocationMapState state,
  LocationMapController controller,
);

/// Seam del mapa: en producción construye un `FlutterMap` (OpenStreetMap);
/// los tests lo sustituyen por un widget simple para no depender de la red
/// (07.5 §7).
final mapViewBuilderProvider = Provider<MapaSeleccionBuilder>((ref) {
  return (state, controller) =>
      _FlutterMapView(state: state, controller: controller);
});

class SelectLocationMapScreen extends ConsumerWidget {
  const SelectLocationMapScreen({super.key, this.inicial});

  final LatLng? inicial;

  static Future<SeleccionUbicacion?> mostrar(
    BuildContext context, {
    LatLng? inicial,
  }) => Navigator.of(context).push<SeleccionUbicacion>(
    MaterialPageRoute(
      builder: (_) => SelectLocationMapScreen(inicial: inicial),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = locationMapControllerProvider(inicial);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final mapa = ref.watch(mapViewBuilderProvider)(state, controller);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubicar en el mapa')),
      body: Stack(
        children: [
          Positioned.fill(child: mapa),
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Icon(
                  Icons.location_pin,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'selector-map-gps',
              tooltip: 'Mi ubicación',
              onPressed: state.cargandoSugerencia
                  ? null
                  : () => controller.ubicarConGps(),
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.lg,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.error != null) ...[
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (state.sugerencia == null && state.error == null)
                      const Text(
                        'Arrastra el mapa hasta colocar el pin sobre tu puerta',
                      ),
                    if (state.sugerencia?.calle != null)
                      Text(
                        state.sugerencia!.calle!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (state.sugerencia?.ciudad != null)
                      Text(
                        state.sugerencia!.ciudad!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (state.cargandoSugerencia) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Usar esta ubicación',
                      onPressed: () => Navigator.of(context).pop(
                        SeleccionUbicacion(
                          ubicacion: state.centro,
                          sugerencia: state.sugerencia,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FlutterMap real (OpenStreetMap): gestiona el vuelo hasta
/// [LocationMapState.centro] cuando el cambio viene de fuera (GPS); los
/// arrastres actualizan el estado y, tras un debounce, disparan la
/// geocodificación inversa (sustituye al `onCameraIdle` de Google Maps).
class _FlutterMapView extends StatefulWidget {
  const _FlutterMapView({required this.state, required this.controller});

  final LocationMapState state;
  final LocationMapController controller;

  @override
  State<_FlutterMapView> createState() => _FlutterMapViewState();
}

class _FlutterMapViewState extends State<_FlutterMapView> {
  /// Espera tras el último movimiento de la cámara antes de geocodificar.
  static const _retardoGeocoding = Duration(milliseconds: 400);

  final MapController _mapa = MapController();
  Timer? _debounce;

  @override
  void didUpdateWidget(covariant _FlutterMapView viejo) {
    super.didUpdateWidget(viejo);
    if (widget.state.vueloPendiente &&
        viejo.state.centro != widget.state.centro) {
      _volar();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _volar() {
    _mapa.move(widget.state.centro, _mapa.camera.zoom);
    widget.controller.consumirVuelo();
  }

  void _programarGeocoding() {
    _debounce?.cancel();
    _debounce = Timer(_retardoGeocoding, widget.controller.resolverSugerencia);
  }

  void _alMover(MapCamera camera, bool hasGesture) {
    // Solo los gestos del usuario mueven el estado: los vuelos programados
    // (GPS, toque) ya actualizan `centro` por su cuenta y no deben realimentar.
    if (!hasGesture) {
      return;
    }
    widget.controller.moverCamara(camera.center);
    _programarGeocoding();
  }

  /// Toque en el mapa: el pin, fijo en el centro de la pantalla, salta al
  /// punto tocado y la cámara se centra ahí. Comparte el debounce del arrastre
  /// para que ambas formas de mover el pin geocodifiquen igual.
  void _alTocar(TapPosition tapPosition, LatLng punto) {
    widget.controller.moverCamara(punto);
    _mapa.move(punto, _mapa.camera.zoom);
    _programarGeocoding();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      key: const ValueKey('mapa-seleccion'),
      mapController: _mapa,
      options: MapOptions(
        initialCenter: widget.state.centro,
        initialZoom: 16,
        onPositionChanged: _alMover,
        onTap: _alTocar,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.quickbite.quickbite_mobile',
          maxNativeZoom: 19,
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'Colaboradores de OpenStreetMap',
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
