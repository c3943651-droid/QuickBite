import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Badge de notificación: círculo rojo con el número de elementos sin leer
/// (09 §8.4). Con cero —o un valor inválido— no dibuja nada, para que las
/// pantallas puedan colocarlo siempre sin condicionar su uso.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.color = AppColors.appetiteRed,
  });

  final int count;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }
    return Badge(
      backgroundColor: color,
      textColor: AppColors.white,
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
