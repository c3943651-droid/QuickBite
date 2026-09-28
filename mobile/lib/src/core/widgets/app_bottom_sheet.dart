import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom sheet estándar para opciones contextuales y filtros rápidos
/// (09 §8.7).
///
/// Envuelve `showModalBottomSheet` con lo que todas las pantallas repiten:
/// superficie del tema, esquinas superiores redondeadas, asa de arrastre, título
/// opcional y separación segura. `show` devuelve el valor con el que se cierre
/// la hoja, o `null` si el usuario la descarta.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.softBlack.withValues(alpha: 0.45),
      builder: (context) => _Sheet(title: title, child: child),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetDragHandle(),
              if (title case final title?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              Flexible(child: child),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asa de arrastre de la hoja.
///
/// Flutter expone su equivalente (`_DragHandle`) como privado, así que aquí va
/// la versión de QuickBite: la misma barra de 32x4 que usa `showModalBottomSheet`
/// en Material 3, con el ancho y el color del tema.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.mistGray,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }
}
