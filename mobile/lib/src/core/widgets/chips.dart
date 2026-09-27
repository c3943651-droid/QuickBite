import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tono semántico de un chip de estado (09 §8.4). Cada estado del negocio se
/// mapea a uno de estos seis, de modo que el color nunca se decide en la
/// pantalla que consume el chip.
enum StatusTone { neutral, info, progress, warning, success, danger }

extension StatusToneColor on StatusTone {
  Color get color => switch (this) {
    StatusTone.neutral => AppColors.textGray,
    StatusTone.info => AppColors.infoBlue,
    StatusTone.progress => AppColors.warningYellow,
    StatusTone.warning => AppColors.errorRed,
    StatusTone.success => AppColors.successGreen,
    StatusTone.danger => AppColors.appetiteRed,
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

/// Chip de categoría: fondo gris claro y, cuando está activo, fondo naranja
/// con texto blanco (09 §8.4).
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
    return Container(
      color: selected ? AppColors.quickbiteOrange : AppColors.mistGray,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.white : AppColors.textGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
