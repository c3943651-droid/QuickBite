import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'notification_badge.dart';

/// Barra superior de la app (09 §8.9).
///
/// Unifica el fondo blanco con texto oscuro, la elevación 0 en reposo y nivel 2
/// al hacer scroll, y el título limitado a dos líneas para que los nombres largos
/// (`Preferencias de notificaciones`) no empujen las acciones fuera de pantalla.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.centerTitle = false,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: onBack == null ? null : BackButton(onPressed: onBack),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge,
      ),
      actions: actions,
    );
  }
}

/// Acción de la barra superior pensada para llevar un badge de notificaciones
/// (SCR-NOTIF-01), sin obligar a cada pantalla a montar el `IconButton` a mano.
class NotificationButton extends StatelessWidget {
  const NotificationButton({
    super.key,
    required this.onTap,
    this.icon = Icons.notifications_none,
    this.badgeCount = 0,
  });

  final VoidCallback onTap;
  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: NotificationBadge(
        count: badgeCount,
        child: Icon(icon, color: AppColors.textGray),
      ),
    );
  }
}
