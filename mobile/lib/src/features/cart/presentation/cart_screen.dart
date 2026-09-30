import '../../../core/theme/app_radius.dart';

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
import 'widgets/cart_item_card.dart';

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
      itemBuilder: (context, index) => CartItemCard(item: cart.items[index]),
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
        // Resumen como tarjeta flotante: superficie blanca con borde suave y
        // sombra difusa, en vez de una franja blanca pegada al borde que
        // recortaba contra el fondo claro.
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 24,
              spreadRadius: -6,
              offset: Offset(0, 8),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Subtotal', value: cart.subtotal),
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(label: 'Costo de envío', value: cart.costoEnvio),
            const Divider(height: AppSpacing.lg, color: AppColors.border),
            _SummaryRow(label: 'Total', value: cart.total, isTotal: true),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/checkout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
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
