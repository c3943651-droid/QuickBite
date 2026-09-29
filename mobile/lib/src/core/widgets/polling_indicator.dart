import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indicador discreto de actualización en curso (09 §8.6).
///
/// El requisito de diseño es que *no* interrumpe: no bloquea la pantalla ni
/// ocupa un bloque, así que cuando no hay nada que actualizar devuelve
/// `SizedBox.shrink()` y el layout de la pantalla no se mueve.
class PollingIndicator extends StatelessWidget {
  const PollingIndicator({
    super.key,
    required this.active,
    this.label = 'Actualizando...',
  });

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
