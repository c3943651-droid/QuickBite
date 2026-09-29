import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_colors.dart';

/// Configuración de la interfaz del sistema.
///
/// Android 15 (API 35) aplica **edge-to-edge por defecto** a las apps que
/// compilan contra esa API: ya no se puede opting out con barras opacas. Eso
/// significa que hay que declarar los colores como transparentes y confiar en
/// los `SafeArea` de cada pantalla para que nada quede bajo la muesca o el
/// gesto inferior.
///
/// El caso que se ve en el Moto G15: sin esto, la barra de navegación
/// overlapeaba el botón inferior de "Proceder al pago" y la pantalla de inicio
/// arrancaba con el saludo pegado al reloj.
abstract final class AppSystemUi {
  /// Modo de barras: systemUIEdgeToEdge.
  static const SystemUiMode modo = SystemUiMode.edgeToEdge;

  /// Estilo de las barras del sistema para un brillo dado.
  static SystemUiOverlayStyle estiloPara(Brightness brillo) {
    final oscuro = brillo == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      // Iconos oscuros sobre fondo claro y al revés: sin esto el reloj
      // desaparece en modo claro y se lee negro sobre negro en oscuro.
      statusBarIconBrightness: oscuro ? Brightness.light : Brightness.dark,
      statusBarBrightness: oscuro ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness: oscuro
          ? Brightness.light
          : Brightness.dark,
    );
  }

  /// Aplica edge-to-edge. Se llama una vez al arrancar, antes de `runApp`.
  static Future<void> aplicar() => SystemChrome.setEnabledSystemUIMode(modo);

  /// El overlay del sistema se aplica declarando un `AnnotatedRegion` con
  /// [estiloPara] sobre el árbol de widgets (ver `QuickBiteApp`): `SystemChrome`
  /// no expone un setter de estilo de overlay.
  static const statusBarEsperado = AppColors.background;

  /// Color de la barra de estado que pide el sistema, para los testes.
}
