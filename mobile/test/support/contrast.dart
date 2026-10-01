import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Razón de contraste WCAG entre dos colores opacos.
///
/// Se usa para fijar que un texto se lee sobre su superficie: un estilo sin
/// color explícito puede caer en el `Typography` por defecto de Material, que
/// no respeta ni el modo oscuro ni el de alto contraste.
double contraste(Color a, Color b) {
  double luminancia(Color color) {
    double canal(double c) => c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canal(color.r) +
        0.7152 * canal(color.g) +
        0.0722 * canal(color.b);
  }

  final la = luminancia(a);
  final lb = luminancia(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Color con el que se pinta de verdad un [Text]: el del estilo, o el de la
/// lista de estilos que lo heredan.
Color colorDe(TextStyle? estilo, {TextStyle? heredado}) =>
    estilo?.color ?? heredado?.color ?? const Color(0xFF000000);
