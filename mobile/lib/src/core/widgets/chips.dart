import 'package:flutter/material.dart';

import '../haptics.dart';
import '../theme/app_colors.dart';
import 'soft_card.dart';

/// Tono semántico de un chip de estado (09 §8.4). Cada estado del negocio se
/// mapea a uno de estos seis, de modo que el color nunca se decide en la
/// pantalla que consume el chip.
enum StatusTone { neutral, info, progress, warning, success, danger }

extension StatusToneColor on StatusTone {
  Color get color => switch (this) {
    StatusTone.neutral => AppColors.ink,
    StatusTone.info => AppColors.info,
    StatusTone.progress => AppColors.warning,
    StatusTone.warning => AppColors.error,
    StatusTone.success => AppColors.success,
    StatusTone.danger => AppColors.accentAlt,
  };
}

/// Chip de estado: fondo del color semántico al 20 % y texto del mismo color
/// (09 §8.4).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = tone.color;
    return Container(
      color: color.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final icon?) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de categoría (09 §8.4).
///
/// Rediseño: píldora completa (radio `chip`), borde suave en el estado inactivo
/// y **degradado** en el activo. Antes era un rectángulo de color plano, que
/// leía como un botón y no como un filtro.
///
/// Los colores salen del tema, no de constantes fijas: con `AppColors` pelados
/// la píldora inactiva quedaba blanca con texto ciruela también en modo
/// oscuro, y el borde pizarra 200 se fundía con la superficie nocturna. El
/// texto inactivo siempre conserva contraste AA contra su propia píldora.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oscuro = theme.brightness == Brightness.dark;
    // Los mismos tokens que la tarjeta de la barra flotante: en modo oscuro el
    // `outlineVariant` que genera `ColorScheme.fromSeed` es casi indistinguible
    // de la superficie (1.02:1) y la píldora se fundía con la pantalla.
    final inactivoFondo = theme.colorScheme.surface;
    final inactivoBorde = oscuro ? AppColors.nightBorder : AppColors.border;
    final inactivoTexto = theme.colorScheme.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: selected ? AppGradiente.acento : null,
          color: selected ? null : inactivoFondo,
            borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : inactivoBorde,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              onTap();
            },
          borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    // El chip activo pinta el degradado de marca, que no cambia
                    // con el tema, así que su texto tampoco debe: en modo oscuro
                    // `colorScheme.onPrimary` es un verde casi negro (2.4:1) y
                    // dejaba la etiqueta ilegible sobre el propio acento.
                    color: selected ? AppColors.white : inactivoTexto,
                  ),
                ),
            ),
          ),
        ),
      ),
    );
  }
}
