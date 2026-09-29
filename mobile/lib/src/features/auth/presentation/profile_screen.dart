import '../../../core/theme/app_radius.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/notification_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../notification/presentation/notification_providers.dart';
import '../domain/auth_entities.dart';
import 'auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: error is AppException
              ? error.userMessage
              : 'No pudimos cargar tu perfil. Inténtalo de nuevo.',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (data) => _ProfileBody(profile: data),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si el perfil llega sin rol, se usa el de la sesión: es la misma fuente que
    // aplica el guard del router, así que el hub nunca muestra un conjunto de
    // secciones que contradiga las rutas a las que la persona puede llegar.
    final rol = profile.rol.isNotEmpty
        ? profile.rol
        : (ref.watch(sessionProvider).value?.user.rol ?? 'cliente');
    final isCliente = rol == 'cliente';
    // 07.1 SCR-DEL-06/07: el repartidor no ve direcciones (no entrega a ninguna
    // manualmente) pero sí sus métricas y su interruptor de disponibilidad.
    final isRepartidor = rol == 'repartidor';
    // El `Scaffold` del shell deja en `MediaQuery.padding.bottom` lo que ocupa
    // la barra flotante (su alto fijo más el inset del sistema). Sumarlo evita
    // dos fallos que se vieron en el Moto G15: con solo un margen fijo, "Cerrar
    // sesión" seguía quedándose medio tapado en pantallas con barra de 3
    // botones, y sin margen alguno la última fila no se podía ni tocar.
    final franjaInferior =
        MediaQuery.paddingOf(context).bottom + AppSizes.bottomNavBarGap;

    return ListView(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: franjaInferior,
      ),
      children: [
        _Header(
          nombre: profile.nombre,
          email: profile.email,
          telefono: profile.telefono,
        ),
        const SizedBox(height: AppSpacing.md),
        // Menú agrupado en una tarjeta con separadores: antes las opciones iban
        // sueltas y se leían como un bloque de texto sin jerarquía.
        _GrupoMenu(
          children: [
            _Row(
              icon: Icons.badge_outlined,
              label: 'Editar perfil',
              onTap: () => context.push('/profile/edit'),
            ),
            _Row(
              icon: Icons.lock_outline,
              label: 'Cambiar contraseña',
              onTap: () => context.push('/profile/security/password'),
            ),
            _Row(
              icon: Icons.devices_outlined,
              label: 'Sesiones activas',
              onTap: () => context.push('/profile/security/sessions'),
            ),
            if (isCliente)
              _Row(
                icon: Icons.location_on_outlined,
                label: 'Mis direcciones',
                onTap: () => context.push('/addresses'),
              ),
            if (isRepartidor) ...[
              _Row(
                icon: Icons.insights_outlined,
                label: 'Mis estadísticas',
                onTap: () => context.push('/delivery/stats'),
              ),
              _Row(
                icon: Icons.pedal_bike_outlined,
                label: 'Disponibilidad',
                onTap: () => context.push('/delivery/availability'),
              ),
            ],
            _Row(
              icon: Icons.notifications_none,
              label: 'Notificaciones',
              badgeCount: ref.watch(notificationsNoLeidasProvider),
              onTap: () => context.push('/notifications'),
            ),
            _Row(
              icon: Icons.tune,
              label: 'Preferencias de notificaciones',
              onTap: () => context.push('/profile/notifications'),
            ),
            _Row(
              icon: Icons.palette_outlined,
              label: 'Apariencia',
              onTap: () => context.push('/profile/appearance'),
            ),
            _Row(
              icon: Icons.translate,
              label: 'Idioma y región',
              onTap: () => context.push('/profile/language'),
            ),
            _Row(
              icon: Icons.shield_outlined,
              label: 'Privacidad',
              onTap: () => context.push('/profile/privacy'),
            ),
            _Row(
              icon: Icons.help_outline,
              label: 'Ayuda y soporte',
              onTap: () => context.push('/profile/help'),
            ),
            _Row(
              icon: Icons.info_outline,
              label: 'Acerca de',
              onTap: () => context.push('/profile/about'),
            ),
            _Row(
              icon: Icons.settings_suggest_outlined,
              label: 'Avanzado',
              onTap: () => context.push('/profile/advanced'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _GrupoMenu(
          children: [
            _Row(
              icon: Icons.delete_outline,
              label: 'Eliminar cuenta',
              destructive: true,
              onTap: () => context.push('/profile/delete-account'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: PrimaryButton(
            label: 'Cerrar sesión',
            icon: Icons.logout,
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.nombre,
    required this.email,
    required this.telefono,
  });

  final String nombre;
  final String email;
  final String? telefono;

  @override
  Widget build(BuildContext context) {
    // El encabezado nunca queda en blanco: un nombre vacío (usuario creado sin
    // nombre completo) muestra un marcador en vez de una línea huérfana.
    final nombreVisible = nombre.trim().isEmpty ? 'Usuario QuickBite' : nombre;
    final emailVisible = email.trim();
    final telefonoVisible = telefono?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Avatar con anillo de acento: un `Container` decorado en lugar de
          // `CircleAvatar`, que no admite borde ni sombra.
          Container(
            width: AppSizes.avatar,
            height: AppSizes.avatar,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330D9488),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.inkMuted,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreVisible,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (emailVisible.isNotEmpty)
                  Text(
                    emailVisible,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (telefonoVisible != null && telefonoVisible.isNotEmpty)
                  Text(
                    telefonoVisible,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Agrupa filas de menú en una tarjeta.
///
/// Antes las opciones del perfil iban sueltas una detrás de otra sobre el fondo,
/// sin separación visual: todo leía como un bloque único de texto. En una
/// tarjeta con separadores se distinguen de un vistazo y el toque deja de ser a
/// ciegas.
class _GrupoMenu extends StatelessWidget {
  const _GrupoMenu({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // `SoftCard` y no un `Container`: pone un `Material` transparente dentro,
    // y sin él el `ListTile` pinta su ripple sobre un fondo que no es suyo y
    // el toque deja de verse.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: AppSpacing.lg,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: badgeCount == null
          ? const Icon(Icons.chevron_right)
          : NotificationBadge(
              count: badgeCount!,
              child: const Icon(Icons.chevron_right),
            ),
      onTap: onTap,
    );
  }
}
