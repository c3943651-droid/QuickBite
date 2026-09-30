import 'package:flutter/services.dart';

/// Feedback háptico de las acciones principales.
///
/// Existe como envoltorio y no como `HapticFeedback` directo en cada pantalla
/// por dos motivos: el patrón se puede **desactivar** de un solo sitio (hay
/// personas a las que las vibraciones les incomodan y no se pueden configurar
/// por usuario), y los tests pueden comprobar que la acción principal devuelve
/// feedback sin depender del canal del sistema.
///
/// Android responde a `lightImpact` con una vibración de ~10 ms; en el Moto G15
/// se nota lo justo, sin el temblor del `heavyImpact`.
abstract final class AppHaptics {
  /// Interruptor global. Los tests lo apagan para no depender del sistema.
  static bool enabled = true;

  /// Acción principal: agregar al carrito, aceptar entrega, confirmar pedido.
  static void alToque() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Cambio de valor o de pestaña.
  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Éxito o errorterminal de una operación (pedido confirmado, no se pudo
  /// aceptar).
  static void resultado({required bool exitoso}) {
    if (!enabled) return;
    if (exitoso) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}
