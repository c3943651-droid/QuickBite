import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/notification_entities.dart';
import 'notification_providers.dart';

/// Bandeja de notificaciones del cliente (07.1 SCR-NOTIF-01).
///
/// Cuatro filtros, las no leídas resaltadas, marcado individual al tocar y
/// marcado masivo desde el encabezado. Tocar una notificación de pedido abre
/// su seguimiento (07.1 SCR-ORDER-04).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandeja = ref.watch(notificationsProvider);
    final filtro = ref.watch(notificationFilterProvider);
    final sinLeer = ref.watch(notificationsNoLeidasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '$sinLeer sin leer',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          TextButton(
            onPressed: sinLeer == 0
                ? null
                : () => ref
                      .read(notificationAccionesProvider.notifier)
                      .marcarTodasLeidas(),
            child: const Text('Marcar todas como leídas'),
          ),
        ],
      ),
      body: Column(
        children: [
          _Filtros(
            seleccionado: filtro,
            onSeleccionar: (nuevo) => ref
                .read(notificationFilterProvider.notifier)
                .seleccionar(nuevo),
          ),
          Expanded(
            child: bandeja.when(
              loading: () => const _ListaSkeleton(),
              error: (error, _) => ErrorStateView(
                message: error is AppException
                    ? error.userMessage
                    : 'No pudimos cargar tus notificaciones.',
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (_) => const _Bandeja(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.seleccionado, required this.onSeleccionar});

  final FiltroNotificacion seleccionado;
  final ValueChanged<FiltroNotificacion> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        itemCount: FiltroNotificacion.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filtro = FiltroNotificacion.values[index];
          return CategoryChip(
            label: filtro.etiqueta,
            selected: filtro == seleccionado,
            onTap: () => onSeleccionar(filtro),
          );
        },
      ),
    );
  }
}

class _Bandeja extends ConsumerWidget {
  const _Bandeja();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificaciones = ref.watch(notificationsFiltradasProvider);
    final hayNotificaciones =
        ref.watch(notificationsProvider).value?.isNotEmpty ?? false;

    if (notificaciones.isEmpty) {
      return EmptyStateView(
        message: hayNotificaciones
            ? 'No tienes notificaciones en este filtro.'
            : 'No tienes notificaciones.',
        icon: Icons.notifications_none,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: notificaciones.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notificacion = notificaciones[index];
        return _NotificacionTile(
          notificacion: notificacion,
          onTap: () => _abrir(context, ref, notificacion),
        );
      },
    );
  }

  /// Marcar como leída y, si la notificación es de un pedido, abrir su
  /// seguimiento. El marcado no bloquea la navegación.
  void _abrir(BuildContext context, WidgetRef ref, Notificacion notificacion) {
    if (!notificacion.leido) {
      ref
          .read(notificationAccionesProvider.notifier)
          .marcarLeida(notificacion.id);
    }
    if (notificacion.tienePedido) {
      context.push('/order/${notificacion.pedidoId}');
    }
  }
}

class _NotificacionTile extends StatelessWidget {
  const _NotificacionTile({required this.notificacion, required this.onTap});

  final Notificacion notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sinLeer = !notificacion.leido;

    return Material(
      color: sinLeer
          ? AppColors.mistGray.withValues(alpha: 0.5)
          : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mistGray,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Icon(
                  notificacion.tipo.icono,
                  size: 20,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (sinLeer) ...[
                          Container(
                            key: ValueKey('no-leida-${notificacion.id}'),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.quickbiteOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: sinLeer
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notificacion.mensaje,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _fecha(notificacion.creadoEn),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (notificacion.tienePedido)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.secondaryGray,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    }
    if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    }
    return DateFormat('d MMM').format(fecha);
  }
}

class _ListaSkeleton extends StatelessWidget {
  const _ListaSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final alto in <double>[72, 72, 72])
          Container(
            height: alto,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.mistGray,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
          ),
      ],
    );
  }
}
