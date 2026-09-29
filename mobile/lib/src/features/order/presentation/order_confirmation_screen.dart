import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import 'checkout_providers.dart';

/// 07.1 SCR-CART-03 — Confirmación del pedido recién creado.
///
/// La pantalla no llama a la API: muestra el pedido que dejó el checkout en
/// `lastOrderProvider`. Si se entra por enlace directo sin ese estado, se
/// ofrece volver al catálogo en lugar de inventar datos.
class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(lastOrderProvider);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyStateView(
          message: 'No encontramos este pedido',
          icon: Icons.receipt_long_outlined,
          actionLabel: 'Volver al catálogo',
          onAction: () => context.go('/home'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pedido confirmado')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.md),
            const Center(
              child: Icon(
                Icons.check_circle,
                size: 88,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '¡Pedido confirmado!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Número de pedido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              order.numeroPedido,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.cantidad} × ${item.nombre}'),
                            Text(
                              CurrencyFormatter.format(
                                order.total /
                                    order.cantidadItems *
                                    item.cantidad,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          CurrencyFormatter.format(order.total),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(
                      icon: Icons.place_outlined,
                      label: 'Dirección',
                      value: order.direccionEntrega,
                    ),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Tiempo estimado',
                      value: '${order.tiempoEntregaEstimado} min',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Seguir pedido',
              onPressed: () => context.push('/order/$orderId'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Volver al catálogo',
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
