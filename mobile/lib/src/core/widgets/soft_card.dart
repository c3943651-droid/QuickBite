import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Superficie base de la app.
///
/// Sustituye al `Card` de Material en la mayoría de pantallas. La diferencia que
/// se nota en un móvil real es la sombra: la de Material es dura y se ve como un
/// marco oscuro alrededor de la tarjeta; aquí es difusa, con el borde de 1 px
/// de la paleta haciendo el trabajo de separar del fondo.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color,
    this.radius = AppRadius.card,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Color de fondo; por defecto blanco (pizarra en modo oscuro lo resuelve el
  /// tema del llamador).
  final Color? color;

  final double radius;

  /// La sombra difusa. Las superficies anidadas (dentro de otra tarjeta) la
  /// desactivan: dos sombras difusas apiladas se ensucian.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fondo = color ?? theme.colorScheme.surface;
    final borde = theme.brightness == Brightness.dark
        ? AppColors.nightBorder
        : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borde),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Degradados de marca.
///
/// Centralizados aquí para que un botón, un banner y una píldora activa usen
/// exactamente la misma rampa: dos degradados parecidos pero distintos se
/// notan como descuido.
abstract final class AppGradiente {
  /// Rampa del acento: esmeralda → esmeralda profundo.
  static const LinearGradient acento = LinearGradient(
    colors: [AppColors.accent, AppColors.accentDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Rampa de la ficha destacada del catálogo: acento → cobalto.
  static const LinearGradient destacado = LinearGradient(
    colors: [AppColors.accent, AppColors.accentAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Rampa de los encabezados: ciruela → pizarra. Da profundidad al header sin
  /// gritar, y mantiene el texto blanco con contraste alto.
  static const LinearGradient encabezado = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Aplica un degradante de marca a un hijo.
///
/// Envuelve el contenido en el contenedor decorado; el hijo decide su propio
/// relleno, así que sirve tanto para un botón completo como para una píldora.
class BrandGradient extends StatelessWidget {
  const BrandGradient({
    super.key,
    required this.child,
    this.gradient,
    this.radius = AppRadius.button,
  });

  final Widget child;
  final LinearGradient? gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradiente.acento,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260D9488),
            blurRadius: 18,
            spreadRadius: -6,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
