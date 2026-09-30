import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/soft_card.dart';

/// Encabezado del catálogo (07.1 SCR-CAT-01).
///
/// Antes era una fila de texto sobre el fondo de la app. Ahora es una banda con
/// degradado oscuro: separa el encabezado del contenido sin necesidad de una
/// línea divisoria, y da el punto de anclaje de la pantalla. El degradado es
/// ciruela → pizarra, no el acento, porque aquí manda el texto blanco.
class CatalogHeader extends StatelessWidget {
  const CatalogHeader({
    super.key,
    required this.nombre,
    this.hora,
    this.notificaciones = 0,
    this.onNotificaciones,
  });

  final String nombre;

  /// Puntos sin leer; se dibujan en la campana de la cabecera.
  final int notificaciones;

  final VoidCallback? onNotificaciones;

  /// Hora del día para el saludo. Por defecto, la hora local; se puede inyectar
  /// en los tests para no depender del reloj.
  final int? hora;

  static String saludo(int hora) {
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final momento = hora ?? DateTime.now().hour;

    // La banda es oscura y llega hasta el borde superior, así que declara su
    // propio estilo de overlay: sin esto hereda el global de la app, que en
    // modo claro pone iconos de estado OSCUROS y los pintaba de negro sobre el
    // degradado (reloj y batería invisibles).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradiente.encabezado),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${saludo(momento)}, $nombre',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '¿Qué te pides hoy?',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                _Campana(
                  notificaciones: notificaciones,
                  onTap: onNotificaciones,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de notificaciones de la cabecera.
///
/// Va en su propia clase porque el `Stack` de la insignia necesita `clipBehavior:
/// Clip.none` y el `GestureDetector` de dentro necesita salir del padding del
/// `Row`: mezclarlo inline dejaba el bloque con la sangría imposible de leer.
class _Campana extends StatelessWidget {
  const _Campana({required this.notificaciones, this.onTap});

  final int notificaciones;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notificaciones',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSizes.avatar - 28,
          height: AppSizes.avatar - 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, color: AppColors.white),
              if (notificaciones > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.chip),
                      ),
                    ),
                    child: Text(
                      '$notificaciones',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de la cabecera del catálogo: la greeting en forma de píldora.
class GreetingChip extends StatelessWidget {
  const GreetingChip({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(texto, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
