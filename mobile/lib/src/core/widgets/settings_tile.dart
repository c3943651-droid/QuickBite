import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Encabezado de sección en las pantallas de ajustes (09 §5.3).
///
/// Antes estaba copiado como `_Seccion` en tres pantallas; se extrae aquí para
/// que las nuevas no añadan una cuarta copia.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Fila de navegación de las pantallas de ajustes.
///
/// El mismo patrón que las filas de Perfil: icono, etiqueta y flecha, con
/// soporte para insignia y para marcar la fila como destructiva.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: destructive ? TextStyle(color: color) : null),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      trailing:
          trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}
