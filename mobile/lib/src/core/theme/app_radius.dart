/// Radios y tamaños compartidos.
///
/// Viven en su propio archivo (y no en `app_colors.dart`) porque son geometría,
/// no color: `AppColors` documenta la paleta de marca y este archivo el aspecto
/// de las superficies.
abstract final class AppRadius {
  static const double button = 14;
  static const double card = 18;
  static const double field = 12;
  static const double image = 16;
  static const double modal = 24;

  /// Píldora: chips y etiquetas de estado.
  static const double chip = 999;
}

/// Alturas de los componentes, en píxeles lógicos.
abstract final class AppSizes {
  /// Alto del botón principal (09 §8.1: 48 px).
  static const double buttonHeight = 52;

  /// Lado del avatar de perfil.
  static const double avatar = 72;

  /// Objetivo táctil mínimo de Android (48 px) para iconos pulsables.
  static const double minTapTarget = 48;

  /// Franja que el contenido debe dejar libre al final de una lista para que la
  /// barra de navegación flotante no tape las últimas filas.
  ///
  /// El shell usa `extendBody: true`, así que el cuerpo de la pantalla se
  /// dibuja **debajo** de la barra: sin este margen, "Avanzado" o "Cerrar
  /// sesión" quedaban atrapados detrás de ella y no había forma de verlos ni de
  /// tocarlos.
  ///
  /// Son solo los **px fijos** de la barra (`NavigationBar` + el `AppSpacing.md`
  /// que la separa del borde). La parte variable —el inset del sistema— la
  /// aporta `MediaQuery.paddingOf(context).bottom`, que el `Scaffold` ya deja
  /// medido en el cuerpo: sin ella, un `100` a pelo tapaba el botón en el Moto
  /// G15 con barra de 3 botones.
  static const double bottomNavBarHeight = 80 + 16;

  /// Respiro entre el último elemento de una lista y la barra flotante, para
  /// que la fila no quede pegada al borde de la barra.
  static const double bottomNavBarGap = 16;
}
