import 'package:geolocator/geolocator.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';

/// Servicio que abstrae las llamadas a [GeolocatorPlatform] para consultar
/// y solicitar permisos de ubicación GPS.
///
/// Diseñado para inyección de dependencias: acepta una instancia de
/// [GeolocatorPlatform] en el constructor, lo que permite sustituirla
/// por un mock en los tests unitarios sin necesidad de hardware ni GPS real.
///
/// ## Ejemplo de uso con Riverpod
/// ```dart
/// final locationPermissionServiceProvider = Provider((ref) {
///   return LocationPermissionService();
/// });
/// ```
class LocationPermissionService {
  /// Construye el servicio usando la plataforma proporcionada, o la instancia
  /// por defecto de [GeolocatorPlatform] si no se inyecta ninguna.
  LocationPermissionService({GeolocatorPlatform? platform})
      : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;

  /// Consulta el estado actual del permiso de ubicación sin mostrar diálogos.
  ///
  /// Orden de evaluación:
  /// 1. Si el servicio GPS del dispositivo está desactivado → [LocationPermissionStatus.serviceDisabled].
  /// 2. Mapea el [LocationPermission] de `geolocator` al enum de dominio.
  Future<LocationPermissionStatus> checkStatus() async {
    final serviceEnabled = await _platform.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final permission = await _platform.checkPermission();
    return _mapPermission(permission);
  }

  /// Solicita el permiso de ubicación al usuario si corresponde.
  ///
  /// - Si el servicio GPS está apagado, devuelve [LocationPermissionStatus.serviceDisabled]
  ///   sin mostrar ningún diálogo.
  /// - Si el permiso ya es [LocationPermission.deniedForever], devuelve
  ///   [LocationPermissionStatus.deniedForever] sin relanzar la solicitud
  ///   (el sistema no mostraría el diálogo de todas formas).
  /// - En cualquier otro caso, invoca [GeolocatorPlatform.requestPermission]
  ///   y mapea el resultado.
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await _platform.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final current = await _platform.checkPermission();
    if (current == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    final requested = await _platform.requestPermission();
    return _mapPermission(requested);
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always => LocationPermissionStatus.always,
      LocationPermission.whileInUse => LocationPermissionStatus.whenInUse,
      LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
      LocationPermission.denied => LocationPermissionStatus.denied,
      // unableToDetermine / unableToDeterminePermission
      _ => LocationPermissionStatus.notDetermined,
    };
  }
}
