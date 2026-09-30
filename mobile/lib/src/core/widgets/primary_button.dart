import 'package:flutter/material.dart';

import '../haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'soft_card.dart';

/// Botón primario de la app.
///
/// Se apoya en `FilledButton` de Material —no en un `Container` imitando un
/// botón— para conservar ripple, foco de teclado y Semantics, y pone el
/// degradado **detrás**: el botón queda transparente y la rampa se ve a través.
/// Así el aspecto cambia sin perder accesibilidad ni romper los tests que
/// buscan el botón por etiqueta.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null && !isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: activo
            ? AppGradiente.acento
            : const LinearGradient(
                colors: [AppColors.surfaceMuted, AppColors.border],
              ),
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: activo
            ? const [
                BoxShadow(
                  color: Color(0x330D9488),
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.inkSoft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStylesDeBoton.estilo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        // Sin esto, un botón deshabilitado seguía siendo "activable" para el
        //TalkBack y para la semántica de Material, porque el envoltorio nunca
        //-era nulo.
        onPressed: activo
            ? () {
                AppHaptics.alToque();
                onPressed?.call();
              }
            : null,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flexible para que una etiqueta larga se recorte en vez de
                  // desbordar el botón en pantallas estrechas (nunca debe
                  // aparecer la franja yellow-black de RenderFlex).
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (icon case final icono) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(icono, size: 18, color: AppColors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Botón secundario: superficie blanca con borde de acento.
///
/// Es la acción alternativa de una pantalla; por eso se apoya en la superficie
/// en vez de en el degradado, para que la jerarquía sea evidente.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1.5),
        disabledForegroundColor: AppColors.inkSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : Text(label),
    );
  }
}

/// Tipografía del botón, en un sitio para que primario y secundario no se
/// separen con el tiempo.
abstract final class AppTextStylesDeBoton {
  static const estilo = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
