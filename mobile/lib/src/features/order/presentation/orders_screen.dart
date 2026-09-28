import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/order_entities.dart';
import 'estado_pedido_ui.dart';
import 'order_list_providers.dart';

/// Historial de pedidos (07.1 SCR-ORDER-03). Cinco chips de estado y filtrado
/// en cliente: la API no tiene filtro y un pedido cambia de estado mientras se
/// mira la lista.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(ordersProvider);
    final filtro = ref.watch(orderFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: Column(
        children: [
          _Filtros(
            seleccionado: filtro,
            onSeleccionar: (nuevo) =>
                ref.read(orderFilterProvider.notifier).seleccionar(nuevo),
          ),
          Expanded(
            child: pedidos.when(
              loading: () => const _ListaSkeleton(),
              error: (error, _) => _OrdersError(
                error: error is AppException
                    ? error
                    : const UnexpectedException(
                        'No pudimos cargar tus pedidos.',
                      ),
                onRetry: () => ref.invalidate(ordersProvider),
              ),
              data: (_) => const _Lista(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.seleccionado, required this.onSeleccionar});

  final FiltroPedido seleccionado;
  final ValueChanged<FiltroPedido> onSeleccionar;

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
        itemCount: FiltroPedido.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filtro = FiltroPedido.values[index];
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

class _Lista extends ConsumerWidget {
  const _Lista();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(ordersFiltradosProvider);
    final hayPedidos = ref.watch(ordersProvider).value?.isNotEmpty ?? false;

    if (pedidos.isEmpty) {
      return EmptyStateView(
        message: hayPedidos
            ? 'No tienes pedidos en este estado.'
            : 'No tienes pedidos todavía.',
        icon: Icons.receipt_long_outlined,
        actionLabel: hayPedidos ? null : 'Ver el menú',
        onAction: hayPedidos ? null : () => context.go('/home'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: pedidos.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _OrderCard(pedido: pedidos[index]),
    );
  }
}

/// Resumen de un pedido: número, fecha, estado, cantidad de artículos y total.
/// Los artículos no vienen en `GET /orders` (solo en el detalle), así que la
/// tarjeta no los inventa.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.pedido});

  final Order pedido;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/order/${pedido.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pedido.numeroPedido,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StatusChip(
                  label: pedido.estadoPedido.etiqueta,
                  tone: pedido.estadoPedido.tone,
                  icon: pedido.estadoPedido.icono,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              pedido.creadoEn == null
                  ? 'Sin fecha'
                  : DateFormat(
                      'd MMM yyyy · HH:mm',
                      'es',
                    ).format(pedido.creadoEn!.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryGray,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pedido.cantidadItems == 0
                      ? 'Detalle del pedido'
                      : '${pedido.cantidadItems} artículos',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  CurrencyFormatter.format(pedido.total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaSkeleton extends StatelessWidget {
  const _ListaSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const _CardSkeleton(),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.mistGray,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorStateView(message: error.userMessage, onRetry: onRetry);
  }
}
