import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/cart_entities.dart';
import 'cart_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu carrito'),
        actions: [
          if (cart.value case final data? when !data.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Vaciar carrito'),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (cart) {
          AsyncError(:final error) => ErrorStateView(
            message: error is AppException
                ? error.userMessage
                : 'No pudimos cargar tu carrito.',
            onRetry: () => ref.read(cartProvider.notifier).refresh(),
          ),
          AsyncData(:final value) when value.isEmpty => EmptyStateView(
            message: 'Tu carrito está vacío',
            icon: Icons.shopping_cart_outlined,
            actionLabel: 'Explorar menú',
            onAction: () => context.go('/home'),
          ),
          AsyncData(:final value) => _CartBody(cart: value),
          _ => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        },
      ),
      bottomNavigationBar: switch (cart) {
        AsyncData(:final value) when !value.isEmpty => _SummaryBar(cart: value),
        _ => null,
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final vaciar = await ConfirmDialog.show(
      context,
      title: '¿Vaciar el carrito?',
      message: 'Se quitarán todos los productos del carrito.',
      confirmLabel: 'Sí, vaciar',
      destructive: true,
    );
    if (!vaciar || !context.mounted) {
      return;
    }
    try {
      await ref.read(cartProvider.notifier).clear();
    } on AppException catch (error) {
      if (context.mounted) {
        AppSnackbar.showError(context, error.userMessage);
      }
    } on Exception {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          'No se pudo vaciar el carrito. Inténtalo de nuevo.',
        );
      }
    }
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _CartItemTile(item: cart.items[index]),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(url: item.imagenUrl, nombre: item.nombre),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (item.opciones.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        item.opciones.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (item.observaciones != null &&
                      item.observaciones!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Nota: ${item.observaciones}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _QuantityStepper(
                        cantidad: item.cantidad,
                        onChanged: (value) =>
                            notifier.setQuantity(item.id, value),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      IconButton(
                        onPressed: () => notifier.removeItem(item.id),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Eliminar del carrito',
                        color: AppColors.errorRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.cantidad, required this.onChanged});

  final int cantidad;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mistGray),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onChanged(cantidad - 1),
            icon: const Icon(Icons.remove, size: 18),
            tooltip: 'Quitar una unidad',
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            onPressed: () => onChanged(cantidad + 1),
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Agregar una unidad',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.mistGray)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Subtotal', value: cart.subtotal),
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(label: 'Costo de envío', value: cart.costoEnvio),
            const Divider(height: AppSpacing.lg),
            _SummaryRow(label: 'Total', value: cart.total, isTotal: true),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/checkout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.quickbiteOrange,
                  minimumSize: const Size(0, AppSizes.buttonHeight),
                ),
                child: const Text('Proceder al pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(CurrencyFormatter.format(value), style: style),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.nombre});

  final String? url;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.mistGray,
        borderRadius: BorderRadius.circular(AppRadius.image),
      ),
      child: url == null || url!.isEmpty
          ? Icon(
              Icons.fastfood_outlined,
              color: AppColors.secondaryGray,
              semanticLabel: nombre,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: Image.network(
                url!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.fastfood_outlined,
                  color: AppColors.secondaryGray,
                  semanticLabel: nombre,
                ),
              ),
            ),
    );
  }
}
