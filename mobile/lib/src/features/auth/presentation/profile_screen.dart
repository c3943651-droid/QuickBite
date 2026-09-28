import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/notification_badge.dart';
import '../../../core/widgets/primary_button.dart';
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
        error: (error, _) => _ProfileError(
          error: error,
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
    final isCliente = profile.rol == 'cliente';
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        _Header(
          nombre: profile.nombre,
          email: profile.email,
          telefono: profile.telefono,
        ),
        const Divider(height: AppSpacing.xl),
        _Row(
          icon: Icons.badge_outlined,
          label: 'Editar perfil',
          onTap: () => context.push('/profile/edit'),
        ),
        _Row(
          icon: Icons.lock_outline,
          label: 'Cambiar contraseña',
          onTap: () => context.push('/profile/security'),
        ),
        if (isCliente)
          _Row(
            icon: Icons.location_on_outlined,
            label: 'Mis direcciones',
            onTap: () => context.push('/addresses'),
          ),
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
        const Divider(height: AppSpacing.xl),
        _Row(
          icon: Icons.delete_outline,
          label: 'Eliminar cuenta',
          destructive: true,
          onTap: () => context.push('/profile/delete-account'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.quickbiteOrange,
            child: Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: Theme.of(context).textTheme.titleLarge),
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
                if (telefono != null)
                  Text(telefono!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
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

class _ProfileError extends ConsumerWidget {
  const _ProfileError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = error;
    final message = failure is AppException
        ? failure.userMessage
        : 'No pudimos cargar tu perfil. Inténtalo de nuevo.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
