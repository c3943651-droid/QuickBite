import 'package:flutter/material.dart';

/// Paleta de marca de QuickBite.
///
/// Escala pizarra (slate) para superficies y texto, con un único acento teal.
/// La regla que motiva la paleta: **los colores cálidos no se usan como acento**
/// —el naranja de la identidad anterior se confundía con "descuento" y
/// "urgente"—, así que el acento es frío y el contenido manda.
///
/// Contraste verificado en `test/core/theme/premium_palette_test.dart`: texto
/// principal 14.6:1 sobre el fondo, muy por encima del 4.5:1 de WCAG AA.
abstract final class AppColors {
  /// Blanco puro para texto e iconos **sobre** el acento o superficies oscuras.
  /// Sobre superficies claras se usa [ink].
  static const Color white = Color(0xFFFFFFFF);

  // Superficies
  /// Fondo de pantalla: pizarra muy clara, más suave que el blanco puro para
  /// que las tarjetas blancas se recorten sin necesidad de bordes gruesos.
  static const Color background = Color(0xFFF8FAFC);

  /// Superficie de tarjeta y de app bar: blanco puro.
  static const Color surface = Color(0xFFFFFFFF);

  /// Superficie secundaria (chips inactivos, bloques): pizarra 100.
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  /// Borde suave de tarjeta y separador: pizarra 200.
  static const Color border = Color(0xFFE2E8F0);

  // Acento
  /// Verde esmeralda: botones primarios, estado activo, iconos de acción.
  static const Color accent = Color(0xFF0D9488);

  /// Final del degradado del acento: una parada más profunda para que el
  /// botón no se lea como un rectángulo de color plano.
  static const Color accentDeep = Color(0xFF0F766E);

  /// Acento secundario: cobalto, para distinguirlo del esmeralda cuando
  /// conviven dos acentos en la misma pantalla.
  static const Color accentAlt = Color(0xFF2563EB);

  // Texto
  /// Texto principal: ciruela profunda.
  static const Color ink = Color(0xFF0F172A);

  /// Texto secundario: pizarra 600. El 500 (#64748B) se queda en 4.3:1 sobre
  /// el fondo, apenas por debajo de AA, así que se bajó un escalón.
  static const Color inkMuted = Color(0xFF475569);

  /// Íconos terciarios, separadores y placeholders. Exento de contraste AA por
  /// no ser texto informativo, pero se mantiene por encima de 2:1 para que no
  /// desaparezca a pleno sol.
  static const Color inkSoft = Color(0xFF94A3B8);

  // Semánticos
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);

  /// El aviso usa ámbar quemado en vez de amarillo: el amarillo puro sobre
  /// blanco no llega a 3:1 y es el color peor perceptible en pantallas al sol.
  static const Color warning = Color(0xFFB45309);
  static const Color info = AppColors.accentAlt;

  // Modo oscuro
  /// Pizarra profunda, no negro plano: el negro puro "#121212" dejaba los
  /// bordes de tarjeta invisibles y el conjunto se veía roto.
  static const Color nightBackground = Color(0xFF0B1220);
  static const Color nightSurface = Color(0xFF111C2E);
  static const Color nightBorder = Color(0xFF1E293B);
  static const Color nightInk = Color(0xFFF1F5F9);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
