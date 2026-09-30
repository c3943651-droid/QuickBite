import '../theme/app_radius.dart';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Diálogo de confirmación para acciones críticas (09 §8.7).
///
/// La regla del diseño es tajante: *toda* acción destructiva pasa por aquí, así
/// que el diálogo nunca lanza. Devolver `Future<bool>` obliga al llamador a
/// decidir qué hacer, en lugar de poder ignorar el resultado.
abstract final class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Volver',
    bool destructive = false,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? AppColors.error : null,
              foregroundColor: destructive ? AppColors.white : null,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    // Se cerró tocando fuera: no hay decisión, luego no hay acción.
    return resultado ?? false;
  }
}
