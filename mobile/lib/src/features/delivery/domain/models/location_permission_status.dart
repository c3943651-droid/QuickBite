/// Representa el estado del permiso de ubicación GPS en el dispositivo.
///
/// Este enum es agnóstico a la plataforma y sirve como capa de dominio
/// desacoplada de `geolocator`, lo que permite pruebas unitarias sin
/// depender del hardware o del sistema operativo.
enum LocationPermissionStatus {
  /// El servicio GPS del dispositivo está desactivado (Settings > Location Off).
  /// Requiere redirigir al usuario a la configuración del dispositivo.
  serviceDisabled,

  /// El usuario no ha respondido la solicitud de permisos aún.
  notDetermined,

  /// Permiso concedido sólo mientras la app está en primer plano
  /// (`ACCESS_FINE_LOCATION` / `When In Use`).
  whenInUse,

  /// Permiso concedido también en segundo plano
  /// (`ACCESS_BACKGROUND_LOCATION` / `Always`).
  always,

  /// El usuario denegó el permiso pero puede volver a otorgarlo.
  denied,

  /// El usuario denegó el permiso de forma permanente (o "No preguntar más").
  /// Sólo se puede resolver desde la configuración de la app.
  deniedForever,
}
